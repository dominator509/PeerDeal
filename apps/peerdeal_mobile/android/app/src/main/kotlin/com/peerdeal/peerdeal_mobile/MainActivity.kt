package com.peerdeal.peerdeal_mobile

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var secureKeyStorageHandler: SecureKeyStorageHandler? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val handler = SecureKeyStorageHandler(this)
        secureKeyStorageHandler = handler
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            SecureKeyStorageHandler.CHANNEL_NAME,
        ).setMethodCallHandler(handler)
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            SecureKeyStorageHandler.CHANNEL_NAME,
        ).setMethodCallHandler(null)
        secureKeyStorageHandler?.close()
        secureKeyStorageHandler = null
        super.cleanUpFlutterEngine(flutterEngine)
    }
}
