package com.peerdeal.peerdeal_mobile

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var secureKeyStorageHandler: SecureKeyStorageHandler? = null
    private var captureProtectionHandler: CaptureProtectionHandler? = null
    private var appStorageDirectoryHandler: AppStorageDirectoryHandler? = null
    private var nativeTransportHandler: NativeTransportHandler? = null
    private var localNetworkHandler: LocalNetworkHandler? = null

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

        val appStorageHandler = AppStorageDirectoryHandler(this)
        appStorageDirectoryHandler = appStorageHandler
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            AppStorageDirectoryHandler.CHANNEL_NAME,
        ).setMethodCallHandler(appStorageHandler)

        val transportHandler = NativeTransportHandler(this)
        nativeTransportHandler = transportHandler
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            NativeTransportHandler.CHANNEL_NAME,
        ).setMethodCallHandler(transportHandler)

        val localNetworkHandler = LocalNetworkHandler(this)
        this.localNetworkHandler = localNetworkHandler
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            LocalNetworkHandler.CHANNEL_NAME,
        ).setMethodCallHandler(localNetworkHandler)
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
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            AppStorageDirectoryHandler.CHANNEL_NAME,
        ).setMethodCallHandler(null)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            NativeTransportHandler.CHANNEL_NAME,
        ).setMethodCallHandler(null)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            LocalNetworkHandler.CHANNEL_NAME,
        ).setMethodCallHandler(null)
        secureKeyStorageHandler?.close()
        secureKeyStorageHandler = null
        captureProtectionHandler = null
        appStorageDirectoryHandler = null
        nativeTransportHandler?.close()
        nativeTransportHandler = null
        localNetworkHandler?.close()
        localNetworkHandler = null
        super.cleanUpFlutterEngine(flutterEngine)
    }
}
