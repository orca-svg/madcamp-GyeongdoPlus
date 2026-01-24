package com.example.frontend.wear

import android.annotation.SuppressLint
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.material3.Text
import androidx.compose.material3.LinearProgressIndicator
import androidx.compose.material3.MaterialTheme
import androidx.compose.runtime.*
import androidx.compose.foundation.layout.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import org.json.JSONObject

class WearMainActivity : ComponentActivity() {

    private var receiver: BroadcastReceiver? = null

    @SuppressLint("UnspecifiedRegisterReceiverFlag")
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        val radarState = mutableStateOf("수신 대기 중…")
        val progressState = mutableStateOf<Float?>(null)

        receiver = object : BroadcastReceiver() {
            override fun onReceive(context: Context, intent: Intent) {
                val json = intent.getStringExtra(WearMessageService.EXTRA_JSON) ?: return
                try {
                    val obj = JSONObject(json)
                    val pings = obj.getJSONArray("pings").length()
                    radarState.value = "Ping: $pings"
                    if (!obj.isNull("captureProgress01")) {
                        progressState.value = obj.getDouble("captureProgress01").toFloat()
                    } else {
                        progressState.value = null
                    }
                } catch (_: Throwable) { }
            }
        }
        registerReceiver(receiver, IntentFilter(WearMessageService.ACTION_RADAR))

        setContent {
            MaterialTheme {
                Column(modifier = Modifier.fillMaxSize().padding(12.dp)) {
                    Text("레이더", style = MaterialTheme.typography.titleMedium)
                    Spacer(Modifier.height(8.dp))
                    Text(radarState.value, style = MaterialTheme.typography.bodyMedium)
                    Spacer(Modifier.height(10.dp))

                    val p = progressState.value
                    if (p != null) {
                        LinearProgressIndicator(progress = { p })
                    }
                }
            }
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        receiver?.let { unregisterReceiver(it) }
        receiver = null
    }
}
