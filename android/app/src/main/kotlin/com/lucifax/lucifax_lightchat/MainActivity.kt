package com.lucifax.lucifax_lightchat

import android.app.PictureInPictureParams
import android.content.Context
import android.content.pm.PackageManager
import android.media.AudioDeviceInfo
import android.media.AudioManager
import android.os.Build
import android.util.Rational
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val PIP_CHANNEL = "com.lucifax.lucifax_lightchat/pip"
    private val AUDIO_CHANNEL = "com.lucifax.lucifax_lightchat/audio"
    private var isInCall = false

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // PiP Method Channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, PIP_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "enterPip" -> {
                    val success = enterPipMode()
                    result.success(success)
                }
                "setInCall" -> {
                    isInCall = call.argument<Boolean>("inCall") ?: false
                    updatePipParams()
                    result.success(true)
                }
                "isPipSupported" -> {
                    val supported = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                        packageManager.hasSystemFeature(PackageManager.FEATURE_PICTURE_IN_PICTURE)
                    } else {
                        false
                    }
                    result.success(supported)
                }
                else -> result.notImplemented()
            }
        }

        // Audio Routing Method Channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, AUDIO_CHANNEL).setMethodCallHandler { call, result ->
            val audioManager = getSystemService(Context.AUDIO_SERVICE) as? AudioManager
            if (audioManager == null) {
                result.error("AUDIO_ERROR", "AudioManager not available", null)
                return@setMethodCallHandler
            }

            when (call.method) {
                "setAudioRoute" -> {
                    val route = call.argument<String>("route") ?: "speaker"
                    val success = applyAudioRoute(audioManager, route)
                    result.success(success)
                }
                "getAvailableAudioDevices" -> {
                    val devices = getAvailableAudioDevices(audioManager)
                    result.success(devices)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun applyAudioRoute(audioManager: AudioManager, route: String): Boolean {
        return try {
            audioManager.mode = AudioManager.MODE_IN_COMMUNICATION
            when (route) {
                "speaker" -> {
                    audioManager.stopBluetoothSco()
                    audioManager.isBluetoothScoOn = false
                    audioManager.isSpeakerphoneOn = true
                }
                "earpiece" -> {
                    audioManager.stopBluetoothSco()
                    audioManager.isBluetoothScoOn = false
                    audioManager.isSpeakerphoneOn = false
                }
                "bluetooth" -> {
                    audioManager.isSpeakerphoneOn = false
                    audioManager.startBluetoothSco()
                    audioManager.isBluetoothScoOn = true
                }
                else -> {
                    audioManager.isSpeakerphoneOn = true
                }
            }
            true
        } catch (e: Exception) {
            false
        }
    }

    private fun getAvailableAudioDevices(audioManager: AudioManager): List<String> {
        val list = mutableListOf("speaker", "earpiece")
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                val devices = audioManager.getDevices(AudioManager.GET_DEVICES_OUTPUTS)
                for (device in devices) {
                    if (device.type == AudioDeviceInfo.TYPE_BLUETOOTH_SCO ||
                        device.type == AudioDeviceInfo.TYPE_BLUETOOTH_A2DP ||
                        device.type == AudioDeviceInfo.TYPE_BLE_HEADSET) {
                        if (!list.contains("bluetooth")) {
                            list.add("bluetooth")
                        }
                    }
                }
            } else {
                if (audioManager.isBluetoothScoAvailableOffCall || audioManager.isBluetoothA2dpOn) {
                    list.add("bluetooth")
                }
            }
        } catch (_: Exception) {}
        return list
    }

    private fun updatePipParams() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            try {
                val builder = PictureInPictureParams.Builder()
                    .setAspectRatio(Rational(9, 16))
                    .setAutoEnterEnabled(isInCall)
                setPictureInPictureParams(builder.build())
            } catch (_: Exception) {}
        }
    }

    private fun enterPipMode(): Boolean {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            return try {
                val params = PictureInPictureParams.Builder()
                    .setAspectRatio(Rational(9, 16))
                    .build()
                enterPictureInPictureMode(params)
            } catch (e: Exception) {
                false
            }
        }
        return false
    }

    override fun onUserLeaveHint() {
        super.onUserLeaveHint()
        if (isInCall && Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            enterPipMode()
        }
    }
}
