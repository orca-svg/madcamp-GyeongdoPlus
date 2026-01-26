package com.example.frontend.watch

import android.content.Context
import android.util.Log
import org.json.JSONObject
import com.google.android.gms.wearable.Wearable
import com.google.android.gms.wearable.PutDataMapRequest
import kotlinx.coroutines.tasks.await

class WearBridge(private val context: Context) {

    suspend fun isConnected(): Boolean {
        return try {
            val nodes = Wearable.getNodeClient(context).connectedNodes.await()
            nodes.isNotEmpty()
        } catch (e: Exception) {
            Log.w("WearBridge", "[WATCH][ANDROID][TX] isConnected error: ${e.message}")
            false
        }
    }

    suspend fun sendRadarPacket(json: String) {
        try {
            val nodes = Wearable.getNodeClient(context).connectedNodes.await()
            val bytes = json.toByteArray(Charsets.UTF_8)
            for (n in nodes) {
                Wearable.getMessageClient(context).sendMessage(n.id, "/gyeongdo/radar_packet", bytes).await()
            }
            val matchId = extractMatchId(json)
            Log.d("WearBridge", "[WATCH][ANDROID][TX] RADAR_PACKET matchId=$matchId len=${json.length}")
        } catch (e: Exception) {
            Log.w("WearBridge", "[WATCH][ANDROID][TX] sendRadarPacket error: ${e.message}")
        }
    }

    suspend fun sendStateSnapshot(json: String) {
        try {
            val req = PutDataMapRequest.create("/gyeongdo/state").apply {
                dataMap.putString("json", json)
                dataMap.putLong("ts", System.currentTimeMillis())
            }.asPutDataRequest()
            req.setUrgent()
            Wearable.getDataClient(context).putDataItem(req).await()
            val matchId = extractMatchId(json)
            Log.d("WearBridge", "[WATCH][ANDROID][TX] STATE_SNAPSHOT matchId=$matchId len=${json.length}")
        } catch (e: Exception) {
            Log.w("WearBridge", "[WATCH][ANDROID][TX] sendStateSnapshot error: ${e.message}")
        }
    }

    suspend fun sendHapticAlert(json: String) {
        try {
            val nodes = Wearable.getNodeClient(context).connectedNodes.await()
            val bytes = json.toByteArray(Charsets.UTF_8)
            for (n in nodes) {
                Wearable.getMessageClient(context).sendMessage(n.id, "/gyeongdo/haptic", bytes).await()
            }
            val matchId = extractMatchId(json)
            Log.d("WearBridge", "[WATCH][ANDROID][TX] HAPTIC_ALERT matchId=$matchId len=${json.length}")
        } catch (e: Exception) {
            Log.w("WearBridge", "[WATCH][ANDROID][TX] sendHapticAlert error: ${e.message}")
        }
    }

    private fun extractMatchId(json: String): String {
        return try {
            val obj = JSONObject(json)
            obj.optString("matchId", "unknown")
        } catch (_: Exception) {
            "unknown"
        }
    }
}
