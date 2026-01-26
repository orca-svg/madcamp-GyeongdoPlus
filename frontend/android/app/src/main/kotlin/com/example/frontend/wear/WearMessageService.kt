package com.example.frontend.wear

import android.content.Intent
import android.os.VibrationEffect
import android.os.Vibrator
import android.util.Log
import com.google.android.gms.wearable.DataEventBuffer
import com.google.android.gms.wearable.DataMapItem
import com.google.android.gms.wearable.MessageEvent
import com.google.android.gms.wearable.WearableListenerService

class WearMessageService : WearableListenerService() {

    override fun onMessageReceived(messageEvent: MessageEvent) {
        when (messageEvent.path) {
            "/radar_packet" -> {
                val json = String(messageEvent.data, Charsets.UTF_8)
                Log.d("WearMsgSvc", "[WATCH][WEAROS][RX] RADAR_PACKET len=${json.length}")
                val i = Intent(ACTION_RADAR).apply {
                    putExtra(EXTRA_JSON, json)
                }
                sendBroadcast(i)
            }
            "/gyeongdo/haptic" -> {
                Log.d("WearMsgSvc", "[WATCH][WEAROS][RX] HAPTIC_ALERT")
                triggerHaptic()
            }
        }
    }

    override fun onDataChanged(dataEvents: DataEventBuffer) {
        for (event in dataEvents) {
            val item = event.dataItem
            if (item.uri.path == "/gyeongdo/state") {
                val dataMap = DataMapItem.fromDataItem(item).dataMap
                val json = dataMap.getString("json") ?: continue
                Log.d("WearMsgSvc", "[WATCH][WEAROS][RX] STATE_SNAPSHOT len=${json.length}")
                val i = Intent(ACTION_STATE).apply {
                    putExtra(EXTRA_JSON, json)
                }
                sendBroadcast(i)
            }
        }
    }

    private fun triggerHaptic() {
        val v = getSystemService(VIBRATOR_SERVICE) as? Vibrator ?: return
        val effect = VibrationEffect.createOneShot(300, VibrationEffect.DEFAULT_AMPLITUDE)
        v.vibrate(effect)
    }

    companion object {
        const val ACTION_RADAR = "com.example.frontend.wear.RADAR"
        const val ACTION_STATE = "com.example.frontend.wear.STATE"
        const val EXTRA_JSON = "json"
    }
}
