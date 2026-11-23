package com.example.customer_app

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val messenger = flutterEngine.dartExecutor.binaryMessenger
        val preferences = getSharedPreferences("hap_stays_v1", MODE_PRIVATE)
        val channel = MethodChannel(messenger, "hap/stay_storage",
            io.flutter.plugin.common.StandardMethodCodec.INSTANCE, messenger.makeBackgroundTaskQueue())
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "get" -> result.success(preferences.getString(call.arguments as String, null))
                "save", "replace" -> {
                    val key = requireNotNull(call.argument<String>("key"))
                    val value = requireNotNull(call.argument<String>("value"))
                    val replacing = call.method == "replace"
                    if (replacing && preferences.getString(key, null) != call.argument<String>("expected")) {
                        result.success(false)
                    } else if (preferences.edit().putString(key, value).commit()) {
                        result.success(if (replacing) true else null)
                    } else {
                        result.error("save_failed", "Could not save the stay on this device.", null)
                    }
                }
                "read" -> {
                    val prefix = call.arguments as String
                    result.success(preferences.all.filterKeys { it.startsWith(prefix) }.values.toList())
                }
                else -> result.notImplemented()
            }
        }
    }
}
