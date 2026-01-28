package com.example.frontend.wear

import android.content.Intent
import android.os.Build
import android.os.VibrationEffect
import android.os.Vibrator
import android.util.Log
import org.json.JSONObject
import com.google.android.gms.wearable.DataEventBuffer
import com.google.android.gms.wearable.DataMapItem
import com.google.android.gms.wearable.MessageEvent
import com.google.android.gms.wearable.WearableListenerService

class WearMessageService : WearableListenerService() {

    override fun onMessageReceived(messageEvent: MessageEvent) {
        when (messageEvent.path) {
            "/radar_packet", "/gyeongdo/radar_packet" -> {
                val json = String(messageEvent.data, Charsets.UTF_8)
                val matchId = extractMatchId(json)
                Log.d(
                    "WatchBridge",
                    "[WATCH][WEAROS][RX] RADAR_PACKET matchId=$matchId len=${json.length}"
                )
                val i = Intent(ACTION_RADAR).apply {
                    putExtra(EXTRA_JSON, json)
                }
                sendBroadcast(i)
            }
            "/gyeongdo/haptic" -> {
                val json = String(messageEvent.data, Charsets.UTF_8)
                val matchId = extractMatchId(json)
                Log.d(
                    "WatchBridge",
                    "[WATCH][WEAROS][RX] HAPTIC_ALERT matchId=$matchId len=${json.length}"
                )
                triggerHaptic()
            }
            "/gyeongdo/haptic_command" -> {
                val json = String(messageEvent.data, Charsets.UTF_8)
                // Log.d("WatchBridge", "[WATCH][WEAROS][RX] HAPTIC_COMMAND len=${json.length}")
                triggerHapticCommand(json)
            }
        }
    }

    override fun onDataChanged(dataEvents: DataEventBuffer) {
        for (event in dataEvents) {
            val item = event.dataItem
            if (item.uri.path == "/gyeongdo/state") {
                val dataMap = DataMapItem.fromDataItem(item).dataMap
                val json = dataMap.getString("json") ?: continue
                val matchId = extractMatchId(json)
                Log.d(
                    "WatchBridge",
                    "[WATCH][WEAROS][RX] STATE_SNAPSHOT matchId=$matchId len=${json.length}"
                )
                val i = Intent(ACTION_STATE).apply {
                    putExtra(EXTRA_JSON, json)
                }
                sendBroadcast(i)
            }
        }
    }

    private fun triggerHaptic() {
        val v = getSystemService(VIBRATOR_SERVICE) as? Vibrator ?: return
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val effect = VibrationEffect.createOneShot(300, VibrationEffect.DEFAULT_AMPLITUDE)
            v.vibrate(effect)
        } else {
            @Suppress("DEPRECATION")
            v.vibrate(300)
        }
    }

    private fun triggerHapticCommand(json: String) {
        val payload = try {
             JSONObject(json).optJSONObject("payload")
        } catch (_: Exception) { null } ?: return

        val intensity = payload.optString("intensity", "MEDIUM")
        val v = getSystemService(VIBRATOR_SERVICE) as? Vibrator ?: return

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val effect = when (intensity) {
                "HEAVY" -> {
                    // Heartbeat: 0 start, 100ms on, 80ms off, 60ms on, 80ms off, 60ms on
                    VibrationEffect.createWaveform(
                        longArrayOf(0, 100, 80, 60, 80, 60),
                        intArrayOf(0, 255, 0, 180, 0, 180),
                        -1 // No repeat
                    )
                }
                "MEDIUM" -> VibrationEffect.createOneShot(200, 180)
                "LIGHT" -> VibrationEffect.createOneShot(100, 100)
                else -> VibrationEffect.createOneShot(200, 180)
            }
            v.vibrate(effect)
        } else {
            @Suppress("DEPRECATION")
            when (intensity) {
                "HEAVY" -> v.vibrate(longArrayOf(0, 100, 80, 60, 80, 60), -1)
                "MEDIUM" -> v.vibrate(200)
                "LIGHT" -> v.vibrate(100)
                else -> v.vibrate(200)
            }
        }
    }

    private fun extractMatchId(json: String): String {
        return try {
            org.json.JSONObject(json).optString("matchId", "unknown")
        } catch (_: Throwable) {
            "unknown"
        }
    }

    companion object {
        const val ACTION_RADAR = "com.example.frontend.wear.RADAR"
        const val ACTION_STATE = "com.example.frontend.wear.STATE"
        const val EXTRA_JSON = "json"
    }
}
