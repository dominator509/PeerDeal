package com.peerdeal.peerdeal_mobile

import android.content.Context
import android.net.wifi.WifiManager
import android.os.Handler
import android.os.Looper
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.net.DatagramPacket
import java.net.DatagramSocket
import java.net.InetAddress
import java.net.MulticastSocket
import java.net.InetSocketAddress
import java.nio.ByteBuffer
import java.nio.ByteOrder
import java.nio.charset.CharacterCodingException
import java.nio.charset.CodingErrorAction
import java.util.concurrent.ConcurrentLinkedQueue
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors
import java.util.concurrent.RejectedExecutionException

/**
 * Provides the generic byte-frame transport over a bounded local multicast
 * envelope. The envelope is host-private; Dart receives only decoded frames.
 */
internal class NativeTransportHandler(
    context: Context,
) : MethodChannel.MethodCallHandler {
    companion object {
        const val CHANNEL_NAME = "peerdeal/native_bridges/transport"

        private const val GET_CAPABILITY = "getCapability"
        private const val SEND_FRAME = "sendFrame"
        private const val RECEIVE_FRAMES = "receiveFrames"
        private const val MULTICAST_ADDRESS = "239.255.42.99"
        private const val PORT = 40442
        private const val MAX_PAYLOAD_BYTES = 60 * 1024
        private const val MAX_ID_BYTES = 256
        private const val MAX_QUEUE_SIZE = 512
        private const val MAX_BATCH_SIZE = 64
        private const val HEADER_BYTES = 19
        private const val VERSION: Byte = 1
        private val MAGIC = byteArrayOf('P'.code.toByte(), 'D'.code.toByte(), 'L'.code.toByte(), '1'.code.toByte())
    }

    private val appContext = context.applicationContext
    private val executor: ExecutorService = Executors.newSingleThreadExecutor()
    private val mainHandler = Handler(Looper.getMainLooper())
    private val frames = ConcurrentLinkedQueue<TransportFrame>()
    private val lifecycleLock = Any()
    private var receiveSocket: MulticastSocket? = null
    private var multicastLock: WifiManager.MulticastLock? = null
    @Volatile private var receiverAvailable = false
    @Volatile private var closed = false

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            GET_CAPABILITY -> submit(result, { capabilityPayload(false) }) {
                capabilityPayload(ensureReceiver())
            }
            SEND_FRAME -> submit(result, { failure("Native transport is closed.") }) {
                send(call)
            }
            RECEIVE_FRAMES -> submit(result, { receiveUnavailablePayload() }) {
                receive(call)
            }
            else -> result.notImplemented()
        }
    }

    fun close() {
        var socket: MulticastSocket? = null
        var lock: WifiManager.MulticastLock? = null
        synchronized(lifecycleLock) {
            closed = true
            socket = receiveSocket
            receiveSocket = null
            receiverAvailable = false
            lock = multicastLock
            multicastLock = null
            frames.clear()
        }
        socket?.close()
        releaseMulticastLock(lock)
        executor.shutdown()
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

    private fun postResult(result: MethodChannel.Result, payload: Map<String, Any?>) {
        mainHandler.post { result.success(payload) }
    }

    private fun capabilityPayload(available: Boolean): Map<String, Any?> {
        if (!available) {
            return mapOf(
                "available" to false,
                "sendSupported" to false,
                "receiveSupported" to false,
                "maxPayloadBytes" to 0,
                "notes" to "unavailable",
                "warning" to "Native transport socket is unavailable.",
            )
        }
        return mapOf(
            "available" to true,
            "sendSupported" to true,
            "receiveSupported" to true,
            "maxPayloadBytes" to MAX_PAYLOAD_BYTES,
            "notes" to "android-udp-multicast",
        )
    }

    private fun send(call: MethodCall): Map<String, Any?> {
        if (closed) return failure("Native transport is closed.")
        val frame = frameFromCall(call) ?: return failure("Native transport frame is invalid.")
        val bytes = encode(frame) ?: return failure("Native transport frame is invalid.")
        return try {
            DatagramSocket().use { socket ->
                val packet = DatagramPacket(
                    bytes,
                    bytes.size,
                    InetAddress.getByName(MULTICAST_ADDRESS),
                    PORT,
                )
                socket.send(packet)
            }
            mapOf("success" to true)
        } catch (_: Exception) {
            failure("Native transport send failed.")
        }
    }

    private fun receive(call: MethodCall): Map<String, Any?> {
        if (!ensureReceiver()) {
            return receiveUnavailablePayload()
        }
        val sessionId = safeString(call.argument<Any?>("sessionId"))
        val peerId = safeString(call.argument<Any?>("peerId"))
        if (sessionId == null || peerId == null) {
            return mapOf(
                "available" to false,
                "frames" to emptyList<Map<String, Any?>>(),
                "warning" to "Native transport receive request is invalid.",
            )
        }

        val selected = ArrayList<Map<String, Any?>>(MAX_BATCH_SIZE)
        val retained = ArrayList<TransportFrame>()
        val scanCount = frames.size
        repeat(scanCount) {
            val frame = frames.poll() ?: return@repeat
            if (selected.size < MAX_BATCH_SIZE &&
                frame.sessionId == sessionId &&
                frame.recipientPeerId == peerId
            ) {
                selected.add(frame.toPayload())
            } else {
                retained.add(frame)
            }
        }
        retained.forEach(frames::offer)
        return mapOf("available" to true, "frames" to selected)
    }

    private fun receiveUnavailablePayload(): Map<String, Any?> = mapOf(
        "available" to false,
        "frames" to emptyList<Map<String, Any?>>(),
        "warning" to "Native transport receive socket is unavailable.",
    )

    private fun ensureReceiver(): Boolean {
        synchronized(lifecycleLock) {
            if (closed) return false
            if (receiverAvailable && receiveSocket?.isClosed == false) return true
        }

        var candidateSocket: MulticastSocket? = null
        var candidateLock: WifiManager.MulticastLock? = null
        return try {
            candidateSocket = MulticastSocket(null).apply {
                reuseAddress = true
                bind(InetSocketAddress(PORT))
                timeToLive = 1
                joinGroup(InetAddress.getByName(MULTICAST_ADDRESS))
            }
            val wifiManager = appContext.getSystemService(Context.WIFI_SERVICE) as? WifiManager
            candidateLock = wifiManager?.createMulticastLock("peerdeal-transport")
            if (candidateLock != null) {
                candidateLock?.setReferenceCounted(false)
                candidateLock?.acquire()
            }

            var published = false
            synchronized(lifecycleLock) {
                if (!closed) {
                    receiveSocket = candidateSocket
                    multicastLock = candidateLock
                    receiverAvailable = true
                    published = true
                }
            }
            if (!published) {
                candidateSocket?.close()
                releaseMulticastLock(candidateLock)
                return false
            }

            val receiverSocket = candidateSocket
                ?: return false
            Thread({ receiveLoop(receiverSocket) }, "peerdeal-transport-receiver").apply {
                isDaemon = true
                start()
            }
            true
        } catch (_: Exception) {
            synchronized(lifecycleLock) {
                if (receiveSocket === candidateSocket) {
                    receiveSocket = null
                    multicastLock = null
                    receiverAvailable = false
                }
            }
            candidateSocket?.close()
            releaseMulticastLock(candidateLock)
            false
        }
    }

    private fun releaseMulticastLock(lock: WifiManager.MulticastLock?) {
        if (lock?.isHeld == true) {
            lock.release()
        }
    }

    private fun receiveLoop(socket: MulticastSocket) {
        val buffer = ByteArray(HEADER_BYTES + MAX_PAYLOAD_BYTES)
        while (!closed && !socket.isClosed) {
            try {
                val packet = DatagramPacket(buffer, buffer.size)
                socket.receive(packet)
                val frame = decode(packet.data, packet.length)
                if (frame != null) {
                    synchronized(lifecycleLock) {
                        if (!closed && !socket.isClosed) {
                            while (frames.size >= MAX_QUEUE_SIZE) frames.poll()
                            frames.offer(frame)
                        }
                    }
                }
            } catch (_: Exception) {
                if (closed || socket.isClosed) return
            }
        }
    }

    private fun frameFromCall(call: MethodCall): TransportFrame? {
        val sessionId = safeString(call.argument<Any?>("sessionId")) ?: return null
        val senderPeerId = safeString(call.argument<Any?>("senderPeerId")) ?: return null
        val recipientPeerId = safeString(call.argument<Any?>("recipientPeerId")) ?: return null
        if (senderPeerId == recipientPeerId) return null
        val sequence = (call.argument<Any?>("sequence") as? Number)?.toLong()
            ?.takeIf { it in 1..Int.MAX_VALUE }?.toInt() ?: return null
        val values = call.argument<Any?>("payloadBytes") as? List<*> ?: return null
        if (values.isEmpty() || values.size > MAX_PAYLOAD_BYTES) return null
        val payload = ByteArray(values.size)
        values.forEachIndexed { index, value ->
            val byte = (value as? Number)?.toLong()?.takeIf { it in 0..255 } ?: return null
            payload[index] = byte.toByte()
        }
        return TransportFrame(sessionId, senderPeerId, recipientPeerId, sequence, payload)
    }

    private fun encode(frame: TransportFrame): ByteArray? {
        val session = frame.sessionId.toByteArray(Charsets.UTF_8)
        val sender = frame.senderPeerId.toByteArray(Charsets.UTF_8)
        val recipient = frame.recipientPeerId.toByteArray(Charsets.UTF_8)
        if (session.size > MAX_ID_BYTES || sender.size > MAX_ID_BYTES || recipient.size > MAX_ID_BYTES) {
            return null
        }
        val output = ByteBuffer.allocate(HEADER_BYTES + frame.payload.size).order(ByteOrder.BIG_ENDIAN)
        output.put(MAGIC)
        output.put(VERSION)
        output.putShort(session.size.toShort())
        output.putShort(sender.size.toShort())
        output.putShort(recipient.size.toShort())
        output.putInt(frame.sequence)
        output.putInt(frame.payload.size)
        output.put(session)
        output.put(sender)
        output.put(recipient)
        output.put(frame.payload)
        return output.array()
    }

    private fun decode(bytes: ByteArray, length: Int): TransportFrame? {
        if (length < HEADER_BYTES) return null
        return try {
            val input = ByteBuffer.wrap(bytes, 0, length).order(ByteOrder.BIG_ENDIAN)
            if (!MAGIC.indices.all { input.get() == MAGIC[it] } || input.get() != VERSION) return null
            val sessionLength = input.short.toInt() and 0xffff
            val senderLength = input.short.toInt() and 0xffff
            val recipientLength = input.short.toInt() and 0xffff
            val sequence = input.int
            val payloadLength = input.int
            if (sessionLength > MAX_ID_BYTES || senderLength > MAX_ID_BYTES || recipientLength > MAX_ID_BYTES ||
                sequence < 1 || payloadLength !in 1..MAX_PAYLOAD_BYTES ||
                input.remaining() != sessionLength + senderLength + recipientLength + payloadLength
            ) return null
            val sessionId = readString(input, sessionLength) ?: return null
            val senderPeerId = readString(input, senderLength) ?: return null
            val recipientPeerId = readString(input, recipientLength) ?: return null
            val payload = ByteArray(payloadLength)
            input.get(payload)
            if (senderPeerId == recipientPeerId) return null
            TransportFrame(sessionId, senderPeerId, recipientPeerId, sequence, payload)
        } catch (_: Exception) {
            null
        }
    }

    private fun readString(input: ByteBuffer, length: Int): String? {
        val bytes = ByteArray(length)
        input.get(bytes)
        val text = try {
            Charsets.UTF_8.newDecoder()
                .onMalformedInput(CodingErrorAction.REPORT)
                .onUnmappableCharacter(CodingErrorAction.REPORT)
                .decode(ByteBuffer.wrap(bytes))
                .toString()
        } catch (_: CharacterCodingException) {
            return null
        }
        return safeString(text)
    }

    private fun safeString(value: Any?): String? {
        val text = value as? String ?: return null
        if (text.isEmpty() || text.trim() != text || text.toByteArray(Charsets.UTF_8).size > MAX_ID_BYTES) return null
        if (text.any { it.code < 0x20 || it.code in 0x7f..0x9f }) return null
        return text
    }

    private fun failure(warning: String): Map<String, Any?> =
        mapOf("success" to false, "warning" to warning)

    private data class TransportFrame(
        val sessionId: String,
        val senderPeerId: String,
        val recipientPeerId: String,
        val sequence: Int,
        val payload: ByteArray,
    ) {
        fun toPayload(): Map<String, Any?> = mapOf(
            "sessionId" to sessionId,
            "senderPeerId" to senderPeerId,
            "recipientPeerId" to recipientPeerId,
            "sequence" to sequence,
            "payloadBytes" to payload.map { it.toInt() and 0xff },
        )
    }
}
