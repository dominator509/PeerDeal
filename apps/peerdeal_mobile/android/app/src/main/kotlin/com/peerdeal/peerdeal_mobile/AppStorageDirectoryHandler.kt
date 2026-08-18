package com.peerdeal.peerdeal_mobile

import android.content.Context
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/** Exposes the generic app-private support directory to the Flutter shell. */
internal class AppStorageDirectoryHandler(
    private val context: Context,
) : MethodChannel.MethodCallHandler {
    companion object {
        const val CHANNEL_NAME = "peerdeal/native_bridges/app_storage"

        private const val GET_APP_SUPPORT_DIRECTORY = "getAppSupportDirectory"
        private const val MAX_PATH_BYTES = 4096
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            GET_APP_SUPPORT_DIRECTORY -> result.success(appSupportDirectoryPayload())
            else -> result.notImplemented()
        }
    }

    private fun appSupportDirectoryPayload(): Map<String, Any> {
        val directory = try {
            // Recovery data is private app state and must not enter device backup.
            context.noBackupFilesDir
        } catch (_: Exception) {
            null
        }
        val path = directory?.absolutePath
        if (path == null || !isSafePath(path)) {
            return failurePayload()
        }
        return mapOf(
            "available" to true,
            "directoryPath" to path,
        )
    }

    private fun isSafePath(value: String): Boolean {
        val bytes = value.toByteArray(Charsets.UTF_8)
        if (value.isEmpty() ||
            value.trim() != value ||
            bytes.size > MAX_PATH_BYTES ||
            String(bytes, Charsets.UTF_8) != value
        ) return false
        return value.all { character ->
            character.code >= 0x20 && character.code !in 0x7f..0x9f
        }
    }

    private fun failurePayload(): Map<String, Any> =
        mapOf(
            "available" to false,
            "warning" to "Native app storage directory is unavailable.",
        )
}
