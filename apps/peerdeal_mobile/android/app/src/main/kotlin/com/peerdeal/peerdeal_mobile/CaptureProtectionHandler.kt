package com.peerdeal.peerdeal_mobile

import android.app.Activity
import android.view.WindowManager
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/** Android window capture enforcement for the generic capture channel. */
internal class CaptureProtectionHandler(
    private val activity: Activity,
) : MethodChannel.MethodCallHandler {
    companion object {
        const val CHANNEL_NAME = "peerdeal/native_bridges/capture_protection"

        private const val GET_CAPABILITY = "getCapability"
        private const val SET_BLOCKING = "setBlocking"
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            GET_CAPABILITY -> result.success(capabilityPayload())
            SET_BLOCKING -> setBlocking(call, result)
            else -> result.notImplemented()
        }
    }

    private fun capabilityPayload(): Map<String, Any> =
        mapOf(
            "blockingSupported" to true,
            "obscuringSupported" to true,
            "notes" to "android-window-secure-flag",
        )

    private fun setBlocking(call: MethodCall, result: MethodChannel.Result) {
        val enabled = call.argument<Any?>("enabled") as? Boolean
        if (enabled == null) {
            result.success(failurePayload("Capture protection request is invalid."))
            return
        }

        val applied = try {
            if (enabled) {
                activity.window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
            } else {
                activity.window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
            }
            val flags = activity.window.attributes.flags
            ((flags and WindowManager.LayoutParams.FLAG_SECURE) != 0) == enabled
        } catch (_: Exception) {
            false
        }
        if (!applied) {
            result.success(failurePayload("Capture protection action failed."))
            return
        }
        result.success(
            mapOf(
                "success" to true,
                "blockingEnabled" to enabled,
            ),
        )
    }

    private fun failurePayload(warning: String): Map<String, Any> =
        mapOf(
            "success" to false,
            "blockingEnabled" to false,
            "warning" to warning,
        )
}
