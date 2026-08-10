package com.peerdeal.peerdeal_mobile

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var secureKeyStorageHandler: SecureKeyStorageHandler? = null
    private var captureProtectionHandler: CaptureProtectionHandler? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val handler = SecureKeyStorageHandler(this)
        secureKeyStorageHandler = handler
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            SecureKeyStorageHandler.CHANNEL_NAME,
        ).setMethodCallHandler(handler)

        val captureHandler = CaptureProtectionHandler(this)
        captureProtectionHandler = captureHandler
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CaptureProtectionHandler.CHANNEL_NAME,
        ).setMethodCallHandler(captureHandler)
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            SecureKeyStorageHandler.CHANNEL_NAME,
        ).setMethodCallHandler(null)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CaptureProtectionHandler.CHANNEL_NAME,
        ).setMethodCallHandler(null)
        secureKeyStorageHandler?.close()
        secureKeyStorageHandler = null
        captureProtectionHandler = null
        super.cleanUpFlutterEngine(flutterEngine)
    }
}
