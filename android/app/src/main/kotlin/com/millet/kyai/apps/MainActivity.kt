package com.millet.kyai.apps

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    companion object {
        private const val APP_INFO_CHANNEL = "app/info"
        private const val AUTH_SESSION_CHANNEL = "auth/session"
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        FaceScanChannel.registerWith(flutterEngine, this)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, APP_INFO_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getAppId" -> result.success(BuildConfig.APPLICATION_ID)
                    else -> result.notImplemented()
                }
            }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, AUTH_SESSION_CHANNEL)
            .setMethodCallHandler(AuthSessionSecureStore(applicationContext))
    }

    override fun onDestroy() {
        FaceScanChannel.release()
        super.onDestroy()
    }
}
