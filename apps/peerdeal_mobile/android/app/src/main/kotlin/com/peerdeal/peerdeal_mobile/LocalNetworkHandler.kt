package com.peerdeal.peerdeal_mobile

import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.net.Inet4Address
import java.net.NetworkInterface

/** Reports bounded local-interface facts for the generic local-network bridge. */
internal class LocalNetworkHandler : MethodChannel.MethodCallHandler {
    companion object {
        const val CHANNEL_NAME = "peerdeal/native_bridges/local_network"

        private const val GET_CAPABILITY = "getCapability"
        private const val DISCOVER_PEERS = "discoverPeers"
        private const val MAX_INTERFACE_COUNT = 64
        private const val MAX_INTERFACE_ADDRESS_COUNT = 256
        private const val DISCOVERY_WARNING =
            "Native local-network peer discovery is not configured."
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            GET_CAPABILITY -> result.success(capabilityPayload())
            DISCOVER_PEERS -> result.success(discoveryPayload())
            else -> result.notImplemented()
        }
    }

    private fun capabilityPayload(): Map<String, Any?> {
        val snapshot = networkSnapshot()
        return mapOf(
            "discoverySupported" to false,
            "permissionPromptSupported" to false,
            "broadcastSupported" to snapshot.broadcastSupported,
            "notes" to if (snapshot.available) {
                "android-network-interface-ready"
            } else {
                "unavailable"
            },
            "warning" to if (snapshot.available) {
                DISCOVERY_WARNING
            } else {
                "Native local network is unavailable."
            },
        )
    }

    private fun discoveryPayload(): Map<String, Any?> {
        val snapshot = networkSnapshot()
        return mapOf(
            "permissionGranted" to snapshot.available,
            "foundEndpoints" to emptyList<String>(),
            "interfaceHints" to snapshot.interfaceHints,
            "warning" to if (snapshot.available) {
                DISCOVERY_WARNING
            } else {
                "Native local network is unavailable."
            },
        )
    }

    private fun networkSnapshot(): NetworkSnapshot {
        val interfaces = try {
            val enumeration = NetworkInterface.getNetworkInterfaces()
                ?: return NetworkSnapshot.unavailable()
            val bounded = ArrayList<NetworkInterface>(MAX_INTERFACE_COUNT)
            while (enumeration.hasMoreElements() &&
                bounded.size < MAX_INTERFACE_COUNT
            ) {
                bounded.add(enumeration.nextElement())
            }
            bounded
        } catch (_: Exception) {
            return NetworkSnapshot.unavailable()
        }
        val activeInterfaces = interfaces.filter { networkInterface ->
            try {
                networkInterface.isUp &&
                    !networkInterface.isLoopback &&
                    !networkInterface.isVirtual
            } catch (_: Exception) {
                false
            }
        }
        val hints = activeInterfaces.mapNotNull(::interfaceHint).distinct()
        val broadcastSupported = activeInterfaces.any { networkInterface ->
            try {
                networkInterface.supportsMulticast() &&
                    networkInterface.interfaceAddresses
                        .asSequence()
                        .take(MAX_INTERFACE_ADDRESS_COUNT)
                        .any { address ->
                        address.broadcast != null &&
                            address.address is Inet4Address
                    }
            } catch (_: Exception) {
                false
            }
        }
        return NetworkSnapshot(
            available = activeInterfaces.isNotEmpty(),
            broadcastSupported = broadcastSupported,
            interfaceHints = hints,
        )
    }

    private fun interfaceHint(networkInterface: NetworkInterface): String? {
        val name = try {
            "${networkInterface.name} ${networkInterface.displayName ?: ""}"
                .lowercase()
        } catch (_: Exception) {
            return null
        }
        return when {
            name.contains("wifi") || name.contains("wlan") -> "wifi"
            name.contains("eth") -> "ethernet"
            else -> "other"
        }
    }

    private data class NetworkSnapshot(
        val available: Boolean,
        val broadcastSupported: Boolean,
        val interfaceHints: List<String>,
    ) {
        companion object {
            fun unavailable() = NetworkSnapshot(
                available = false,
                broadcastSupported = false,
                interfaceHints = emptyList(),
            )
        }
    }
}
