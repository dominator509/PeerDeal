package com.peerdeal.peerdeal_mobile

import android.content.Context
import android.net.wifi.WifiManager
import android.os.Handler
import android.os.Looper
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.net.DatagramPacket
import java.net.Inet4Address
import java.net.InetAddress
import java.net.InetSocketAddress
import java.net.MulticastSocket
import java.net.NetworkInterface
import java.net.SocketTimeoutException
import java.nio.ByteBuffer
import java.nio.ByteOrder
import java.nio.charset.CharacterCodingException
import java.nio.charset.CodingErrorAction
import java.util.LinkedHashSet
import java.util.concurrent.ArrayBlockingQueue
import java.util.concurrent.ExecutorService
import java.util.concurrent.RejectedExecutionException
import java.util.concurrent.ThreadPoolExecutor
import java.util.concurrent.TimeUnit

/** Implements the bounded generic PeerDeal local-network discovery contract. */
internal class LocalNetworkHandler(
    context: Context,
) : MethodChannel.MethodCallHandler {
    companion object {
        const val CHANNEL_NAME = "peerdeal/native_bridges/local_network"

        private const val GET_CAPABILITY = "getCapability"
        private const val DISCOVER_PEERS = "discoverPeers"
        private const val ANNOUNCE_PEER = "announcePeer"
        private const val DISCOVERY_ADDRESS = "239.255.42.100"
        private const val DISCOVERY_PORT = 40443
        private const val DEFAULT_ADVERTISED_PORT = 40442
        private const val DISCOVERY_TIMEOUT_MILLIS = 750
        private const val RECEIVE_ERROR_BACKOFF_MILLIS = 25L
        private const val MAX_INTERFACE_COUNT = 64
        private const val MAX_INTERFACE_ADDRESS_COUNT = 256
        private const val MAX_DISCOVERY_ENTRIES = 64
        private const val MAX_ID_BYTES = 256
        private const val HEADER_BYTES = 10
        private const val MAX_PACKET_BYTES = HEADER_BYTES + MAX_ID_BYTES
        private const val VERSION = 1
        private const val QUERY_KIND = 1
        private const val ADVERTISEMENT_KIND = 2
        private val MAGIC = byteArrayOf(
            'P'.code.toByte(),
            'D'.code.toByte(),
            'D'.code.toByte(),
            '1'.code.toByte(),
        )
    }

    private val appContext = context.applicationContext
    private val executor: ExecutorService = ThreadPoolExecutor(
        1,
        1,
        0L,
        TimeUnit.MILLISECONDS,
        ArrayBlockingQueue(8),
    )
    private val mainHandler = Handler(Looper.getMainLooper())
    private val lifecycleLock = Any()
    private var responderSocket: MulticastSocket? = null
    private var responderThread: Thread? = null
    private var multicastLock: WifiManager.MulticastLock? = null
    private var announcedPeerId: String? = null
    private var announcedPort = DEFAULT_ADVERTISED_PORT
    @Volatile private var closed = false

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            GET_CAPABILITY -> submit(result, ::unavailableCapability) {
                capabilityPayload()
            }
            DISCOVER_PEERS -> submit(result, ::unavailableDiscovery) {
                discoveryPayload()
            }
            ANNOUNCE_PEER -> submit(
                result,
                { announcementPayload(false, "Native local-network announcement is unavailable.") },
            ) {
                announcePeerPayload(call)
            }
            else -> result.notImplemented()
        }
    }

    fun close() {
        val socket: MulticastSocket?
        val lock: WifiManager.MulticastLock?
        val thread: Thread?
        synchronized(lifecycleLock) {
            if (closed) return
            closed = true
            socket = responderSocket
            responderSocket = null
            thread = responderThread
            responderThread = null
            lock = multicastLock
            multicastLock = null
            announcedPeerId = null
        }
        socket?.close()
        releaseMulticastLock(lock)
        if (thread != null && thread !== Thread.currentThread()) {
            try {
                thread.join(1_000)
            } catch (_: InterruptedException) {
                Thread.currentThread().interrupt()
            }
        }
        executor.shutdownNow()
    }

    private fun submit(
        result: MethodChannel.Result,
        fallback: () -> Map<String, Any?>,
        operation: () -> Map<String, Any?>,
    ) {
        if (closed) {
            postResult(result, fallback())
            return
        }
        try {
            executor.execute {
                val payload = try {
                    operation()
                } catch (_: Exception) {
                    fallback()
                }
                postResult(result, payload)
            }
        } catch (_: RejectedExecutionException) {
            postResult(result, fallback())
        }
    }

    private fun postResult(
        result: MethodChannel.Result,
        payload: Map<String, Any?>,
    ) {
        mainHandler.post { result.success(if (closed) unavailablePayload(payload) else payload) }
    }

    private fun unavailablePayload(payload: Map<String, Any?>): Map<String, Any?> {
        return when {
            payload.containsKey("published") ->
                announcementPayload(false, "Native local-network handler is closed.")
            payload.containsKey("foundEndpoints") -> unavailableDiscovery()
            else -> unavailableCapability()
        }
    }

    private fun unavailableCapability(): Map<String, Any?> = mapOf(
        "discoverySupported" to false,
        "permissionPromptSupported" to false,
        "broadcastSupported" to false,
        "notes" to "unavailable",
        "warning" to "Native local network is unavailable.",
    )

    private fun unavailableDiscovery(): Map<String, Any?> = mapOf(
        "permissionGranted" to false,
        "foundEndpoints" to emptyList<String>(),
        "interfaceHints" to emptyList<String>(),
        "warning" to "Native local network is unavailable.",
    )

    private fun capabilityPayload(): Map<String, Any?> {
        val snapshot = networkSnapshot()
        return mapOf(
            "discoverySupported" to snapshot.broadcastSupported,
            "permissionPromptSupported" to false,
            "broadcastSupported" to snapshot.broadcastSupported,
            "notes" to if (snapshot.available) {
                "android-udp-multicast-discovery"
            } else {
                "unavailable"
            },
            "warning" to if (snapshot.available) null else {
                "Native local network is unavailable."
            },
        )
    }

    private fun discoveryPayload(): Map<String, Any?> {
        val snapshot = networkSnapshot()
        if (!snapshot.available) return unavailableDiscovery()
        val discovered = discoverEndpoints()
        return mapOf(
            "permissionGranted" to true,
            "foundEndpoints" to discovered.endpoints,
            "interfaceHints" to snapshot.interfaceHints,
            "warning" to discovered.warning,
        )
    }

    private fun announcePeerPayload(call: MethodCall): Map<String, Any?> {
        val peerId = safePeerId(call.argument<Any?>("peerId"))
        val port = positivePort(call.argument<Any?>("port"))
        if (peerId == null || port == null) {
            return announcementPayload(
                false,
                "Native local-network announcement request is invalid.",
            )
        }
        if (!networkSnapshot().available) {
            return announcementPayload(false, "Native local network is unavailable.")
        }
        synchronized(lifecycleLock) {
            if (closed) {
                return announcementPayload(false, "Native local-network handler is closed.")
            }
            announcedPeerId = peerId
            announcedPort = port
        }
        if (!ensureResponder()) {
            return announcementPayload(
                false,
                "Native local-network discovery responder is unavailable.",
            )
        }
        return announcementPayload(true, null)
    }

    private fun ensureResponder(): Boolean {
        synchronized(lifecycleLock) {
            if (closed) return false
            if (responderSocket?.isClosed == false) return true
        }
        val multicastInterface = selectMulticastInterface() ?: return false
        var candidateSocket: MulticastSocket? = null
        var candidateLock: WifiManager.MulticastLock? = null
        try {
            candidateSocket = MulticastSocket(null).apply {
                reuseAddress = true
                bind(InetSocketAddress(DISCOVERY_PORT))
                networkInterface = multicastInterface
                timeToLive = 1
                joinGroup(InetAddress.getByName(DISCOVERY_ADDRESS))
            }
            candidateLock = acquireMulticastLock()
            val thread = Thread(
                { responderLoop(candidateSocket!!) },
                "peerdeal-local-network-responder",
            ).apply { isDaemon = true }
            var published = false
            synchronized(lifecycleLock) {
                if (!closed && responderSocket == null) {
                    responderSocket = candidateSocket
                    multicastLock = candidateLock
                    responderThread = thread
                    published = true
                }
            }
            if (!published) {
                candidateSocket?.close()
                releaseMulticastLock(candidateLock)
                return synchronized(lifecycleLock) {
                    !closed && responderSocket?.isClosed == false
                }
            }
            thread.start()
            return true
        } catch (_: Exception) {
            candidateSocket?.close()
            releaseMulticastLock(candidateLock)
            return false
        }
    }

    private fun responderLoop(socket: MulticastSocket) {
        val buffer = ByteArray(MAX_PACKET_BYTES)
        while (!closed && !socket.isClosed) {
            try {
                val packet = DatagramPacket(buffer, buffer.size)
                socket.receive(packet)
                val decoded = decodePacket(packet.data, packet.length)
                if (decoded?.kind != QUERY_KIND) continue
                val announcement = synchronized(lifecycleLock) {
                    announcedPeerId?.let { peerId -> peerId to announcedPort }
                } ?: continue
                val peerId = announcement.first
                val port = announcement.second
                val response = encodeAdvertisement(peerId, port) ?: continue
                socket.send(
                    DatagramPacket(response, response.size, packet.address, packet.port),
                )
            } catch (_: Exception) {
                if (closed || socket.isClosed) return
                try {
                    Thread.sleep(RECEIVE_ERROR_BACKOFF_MILLIS)
                } catch (_: InterruptedException) {
                    Thread.currentThread().interrupt()
                    return
                }
            }
        }
    }

    private fun discoverEndpoints(): DiscoveryResult {
        val multicastInterface = selectMulticastInterface()
            ?: return DiscoveryResult(
                emptyList(),
                "Native local-network multicast interface is unavailable.",
            )
        return try {
            MulticastSocket(null).use { socket ->
                socket.reuseAddress = true
                socket.bind(InetSocketAddress(0))
                socket.networkInterface = multicastInterface
                socket.timeToLive = 1
                val query = encodeQuery()
                socket.send(
                    DatagramPacket(
                        query,
                        query.size,
                        InetAddress.getByName(DISCOVERY_ADDRESS),
                        DISCOVERY_PORT,
                    ),
                )
                socket.soTimeout = 100
                val deadline = System.nanoTime() +
                    TimeUnit.MILLISECONDS.toNanos(DISCOVERY_TIMEOUT_MILLIS.toLong())
                val ownPeerId = synchronized(lifecycleLock) { announcedPeerId }
                val endpoints = LinkedHashSet<String>()
                while (System.nanoTime() < deadline &&
                    endpoints.size < MAX_DISCOVERY_ENTRIES
                ) {
                    val packet = DatagramPacket(ByteArray(MAX_PACKET_BYTES), MAX_PACKET_BYTES)
                    try {
                        socket.receive(packet)
                    } catch (_: SocketTimeoutException) {
                        continue
                    }
                    val decoded = decodePacket(packet.data, packet.length)
                    if (decoded?.kind != ADVERTISEMENT_KIND ||
                        decoded.peerId == null ||
                        decoded.port == null ||
                        decoded.peerId == ownPeerId ||
                        packet.address !is Inet4Address
                    ) continue
                    val host = packet.address.hostAddress ?: continue
                    endpoints.add("${decoded.peerId}@$host:${decoded.port}")
                }
                DiscoveryResult(endpoints.toList(), null)
            }
        } catch (_: Exception) {
            DiscoveryResult(
                emptyList(),
                "Native local-network discovery lookup failed.",
            )
        }
    }

    private fun acquireMulticastLock(): WifiManager.MulticastLock? {
        val wifiManager = appContext.getSystemService(Context.WIFI_SERVICE)
            as? WifiManager ?: return null
        return try {
            val lock = wifiManager.createMulticastLock("peerdeal-local-network")
            lock.setReferenceCounted(false)
            lock.acquire()
            if (lock.isHeld) lock else null
        } catch (_: Exception) {
            null
        }
    }

    private fun releaseMulticastLock(lock: WifiManager.MulticastLock?) {
        if (lock?.isHeld == true) {
            try {
                lock.release()
            } catch (_: Exception) {
                // Teardown must remain best effort after the socket is closed.
            }
        }
    }

    private fun networkSnapshot(): NetworkSnapshot {
        val interfaces = networkInterfaces()
        val usableInterfaces = interfaces.filter { networkInterface ->
            try {
                networkInterface.isUp &&
                    !networkInterface.isLoopback &&
                    !networkInterface.isVirtual &&
                    hasUsableIpv4Address(networkInterface)
            } catch (_: Exception) {
                false
            }
        }
        val hints = usableInterfaces.mapNotNull(::interfaceHint).distinct()
        val multicastSupported = usableInterfaces.any { networkInterface ->
            try {
                networkInterface.supportsMulticast()
            } catch (_: Exception) {
                false
            }
        }
        return NetworkSnapshot(
            available = usableInterfaces.isNotEmpty(),
            broadcastSupported = multicastSupported,
            interfaceHints = hints,
        )
    }

    private fun networkInterfaces(): List<NetworkInterface> {
        return try {
            val enumeration = NetworkInterface.getNetworkInterfaces()
                ?: return emptyList()
            val bounded = ArrayList<NetworkInterface>(MAX_INTERFACE_COUNT)
            while (enumeration.hasMoreElements() &&
                bounded.size < MAX_INTERFACE_COUNT
            ) {
                bounded.add(enumeration.nextElement())
            }
            bounded
        } catch (_: Exception) {
            emptyList()
        }
    }

    private fun selectMulticastInterface(): NetworkInterface? {
        return networkInterfaces()
            .asSequence()
            .filter { networkInterface ->
                try {
                    networkInterface.isUp &&
                        !networkInterface.isLoopback &&
                        !networkInterface.isVirtual &&
                        networkInterface.supportsMulticast() &&
                        hasUsableIpv4Address(networkInterface)
                } catch (_: Exception) {
                    false
                }
            }
            .sortedWith(
                compareBy<NetworkInterface>(
                    { multicastInterfacePriority(it) },
                    { it.index },
                    { it.name },
                ),
            )
            .firstOrNull()
    }

    private fun multicastInterfacePriority(networkInterface: NetworkInterface): Int {
        val name = try {
            "${networkInterface.name} ${networkInterface.displayName ?: ""}".lowercase()
        } catch (_: Exception) {
            return 2
        }
        return when {
            name.contains("wifi") || name.contains("wlan") -> 0
            name.contains("eth") -> 1
            else -> 2
        }
    }

    private fun hasUsableIpv4Address(networkInterface: NetworkInterface): Boolean =
        try {
            networkInterface.interfaceAddresses
                .asSequence()
                .take(MAX_INTERFACE_ADDRESS_COUNT)
                .any { address ->
                    val inetAddress = address.address
                    inetAddress is Inet4Address &&
                        !inetAddress.isAnyLocalAddress &&
                        !inetAddress.isLoopbackAddress &&
                        !inetAddress.isLinkLocalAddress
                }
        } catch (_: Exception) {
            false
        }

    private fun interfaceHint(networkInterface: NetworkInterface): String? {
        val name = try {
            "${networkInterface.name} ${networkInterface.displayName ?: ""}".lowercase()
        } catch (_: Exception) {
            return null
        }
        return when {
            name.contains("wifi") || name.contains("wlan") -> "wifi"
            name.contains("eth") -> "ethernet"
            else -> "other"
        }
    }

    private fun safePeerId(value: Any?): String? {
        val text = value as? String ?: return null
        val bytes = text.toByteArray(Charsets.UTF_8)
        if (text.isEmpty() || text.trim() != text || bytes.size > MAX_ID_BYTES ||
            text.any { it.code < 0x20 || it.code in 0x7f..0x9f } ||
            text == "none" || text == "unresolved" || text.contains("::")
        ) return null
        return text
    }

    private fun positivePort(value: Any?): Int? {
        val port = when (value) {
            is Int -> value
            is Long -> value.toInt()
            else -> return null
        }
        return port.takeIf { it in 1..65535 }
    }

    private fun encodeQuery(): ByteArray = ByteArray(HEADER_BYTES).also { bytes ->
        MAGIC.copyInto(bytes)
        bytes[4] = VERSION.toByte()
        bytes[5] = QUERY_KIND.toByte()
    }

    private fun encodeAdvertisement(peerId: String, port: Int): ByteArray? {
        val identity = peerId.toByteArray(Charsets.UTF_8)
        if (safePeerId(peerId) == null || identity.size > MAX_ID_BYTES ||
            port !in 1..65535
        ) return null
        return ByteBuffer.allocate(HEADER_BYTES + identity.size)
            .order(ByteOrder.BIG_ENDIAN)
            .put(MAGIC)
            .put(VERSION.toByte())
            .put(ADVERTISEMENT_KIND.toByte())
            .putShort(identity.size.toShort())
            .putShort(port.toShort())
            .put(identity)
            .array()
    }

    private fun decodePacket(data: ByteArray, length: Int): DiscoveryPacket? {
        if (length < HEADER_BYTES || length > MAX_PACKET_BYTES) return null
        for (index in MAGIC.indices) {
            if (data[index] != MAGIC[index]) return null
        }
        if ((data[4].toInt() and 0xff) != VERSION) return null
        val kind = data[5].toInt() and 0xff
        val identityLength = ((data[6].toInt() and 0xff) shl 8) or
            (data[7].toInt() and 0xff)
        val port = ((data[8].toInt() and 0xff) shl 8) or
            (data[9].toInt() and 0xff)
        if (identityLength > MAX_ID_BYTES || length != HEADER_BYTES + identityLength) {
            return null
        }
        if (kind == QUERY_KIND) {
            return if (identityLength == 0 && port == 0) {
                DiscoveryPacket(kind, null, null)
            } else {
                null
            }
        }
        if (kind != ADVERTISEMENT_KIND || port !in 1..65535) return null
        val identityBytes = data.copyOfRange(HEADER_BYTES, length)
        val peerId = try {
            Charsets.UTF_8.newDecoder()
                .onMalformedInput(CodingErrorAction.REPORT)
                .onUnmappableCharacter(CodingErrorAction.REPORT)
                .decode(ByteBuffer.wrap(identityBytes))
                .toString()
        } catch (_: CharacterCodingException) {
            return null
        }
        if (safePeerId(peerId) == null) return null
        return DiscoveryPacket(kind, peerId, port)
    }

    private fun announcementPayload(
        published: Boolean,
        warning: String?,
    ): Map<String, Any?> = mapOf(
        "published" to published,
        "warning" to warning,
    )

    private data class DiscoveryPacket(
        val kind: Int,
        val peerId: String?,
        val port: Int?,
    )

    private data class DiscoveryResult(
        val endpoints: List<String>,
        val warning: String?,
    )

    private data class NetworkSnapshot(
        val available: Boolean,
        val broadcastSupported: Boolean,
        val interfaceHints: List<String>,
    )
}
