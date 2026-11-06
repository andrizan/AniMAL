package com.andrizan.animal

import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "com.andrizan.animal/link_settings",
        ).setMethodCallHandler { call, result ->
            if (call.method == "open") {
                result.success(openLinkSettings())
            } else {
                result.notImplemented()
            }
        }
    }

    private fun openLinkSettings(): Boolean {
        val uri = Uri.parse("package:$packageName")
        val actions = mutableListOf<String>()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            actions.add(Settings.ACTION_APP_OPEN_BY_DEFAULT_SETTINGS)
        }
        actions.add(Settings.ACTION_APPLICATION_DETAILS_SETTINGS)
        for (action in actions) {
            try {
                startActivity(Intent(action, uri))
                return true
            } catch (e: Exception) {
                continue
            }
        }
        return false
    }
}
