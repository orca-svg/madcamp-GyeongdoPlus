package com.example.frontend.wear

import android.content.Intent
import com.google.android.gms.wearable.MessageEvent
import com.google.android.gms.wearable.WearableListenerService

class WearMessageService : WearableListenerService() {

    override fun onMessageReceived(messageEvent: MessageEvent) {
        if (messageEvent.path == "/radar_packet") {
            val json = String(messageEvent.data, Charsets.UTF_8)
            val i = Intent(ACTION_RADAR).apply {
                putExtra(EXTRA_JSON, json)
            }
            sendBroadcast(i)
        }
    }

    companion object {
        const val ACTION_RADAR = "com.example.frontend.wear.RADAR"
        const val EXTRA_JSON = "json"
    }
}
