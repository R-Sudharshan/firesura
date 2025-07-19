package com.example.frontend

import android.content.Context
import android.media.AudioManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "volume_channel").setMethodCallHandler {
            call, result ->
            if (call.method == "getMediaVolume") {
                val audioManager = getSystemService(Context.AUDIO_SERVICE) as AudioManager
                val volume = audioManager.getStreamVolume(AudioManager.STREAM_MUSIC).toDouble()
                val maxVolume = audioManager.getStreamMaxVolume(AudioManager.STREAM_MUSIC).toDouble()
                result.success(volume / maxVolume)
            } else {
                result.notImplemented()
            }
        }
    }
}
