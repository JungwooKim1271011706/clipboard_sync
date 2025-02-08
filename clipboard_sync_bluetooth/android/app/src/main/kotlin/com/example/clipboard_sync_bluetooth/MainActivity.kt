package com.example.clipboard_sync_bluetooth

import android.content.ClipboardManager
import android.content.Context
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "clipboard_channel"
    private lateinit var clipboardManager: ClipboardManager

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        clipboardManager = getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager

        MethodChannel(flutterEngine!!.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "startClipboardWatcher") {
                startClipboardWatcher()
                result.success("Clipboard watching started")
            } else if (call.method == "moveToBackground") {
                moveTaskToBack(true);
                result.success("Moved To background");
            } else if (call.method == "startForegroundService") {
                startForegroundService();
                result.success("Foreground Service started");
            } else {
                result.notImplemented()
            }
        }
    }

    private fun startForegroundService() {
        val intent = Intent(this, ClipboardForegroundService::class.java)

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            startForegroundService(intent) // Foreground Service 시작
        } else {
            startService(intent)
        }
    }

    private fun startClipboardWatcher() {
        clipboardManager.addPrimaryClipChangedListener {
            val clipData = clipboardManager.primaryClip
            if (clipData != null && clipData.itemCount > 0) {
                val clipboardText = clipData.getItemAt(0).text.toString()
                MethodChannel(flutterEngine!!.dartExecutor.binaryMessenger, CHANNEL).invokeMethod("onClipboardChanged", clipboardText)
            }
        }
    }
}
