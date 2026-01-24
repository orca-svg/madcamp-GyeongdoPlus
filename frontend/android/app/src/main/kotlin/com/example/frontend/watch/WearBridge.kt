package com.example.frontend.watch

import android.content.Context
import com.google.android.gms.wearable.Wearable
import kotlinx.coroutines.tasks.await

class WearBridge(private val context: Context) {

    suspend fun isConnected(): Boolean {
        val nodes = Wearable.getNodeClient(context).connectedNodes.await()
        return nodes.isNotEmpty()
    }

    suspend fun sendRadarPacket(json: String) {
        val nodes = Wearable.getNodeClient(context).connectedNodes.await()
        val bytes = json.toByteArray(Charsets.UTF_8)
        for (n in nodes) {
            Wearable.getMessageClient(context).sendMessage(n.id, "/radar_packet", bytes).await()
        }
    }
}
