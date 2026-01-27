package com.example.frontend.wear

import android.annotation.SuppressLint
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.Build
import android.os.Bundle
import android.util.Log
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Button
import androidx.compose.material3.LinearProgressIndicator
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import com.google.android.gms.wearable.Wearable
import kotlinx.coroutines.delay
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.tasks.await
import org.json.JSONObject

class WearMainActivity : ComponentActivity() {

    private var receiver: BroadcastReceiver? = null

    @SuppressLint("UnspecifiedRegisterReceiverFlag")
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        val snapshotState = mutableStateOf<WatchSnapshot?>(null)
        val radarState = mutableStateOf("수신 대기 중…")
        val progressState = mutableStateOf<Float?>(null)

        receiver = object : BroadcastReceiver() {
            override fun onReceive(context: Context, intent: Intent) {
                val json = intent.getStringExtra(WearMessageService.EXTRA_JSON) ?: return
                when (intent.action) {
                    WearMessageService.ACTION_STATE -> {
                        try {
                            snapshotState.value = WatchSnapshot.fromJson(json)
                        } catch (_: Throwable) { }
                    }
                    WearMessageService.ACTION_RADAR -> {
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
            }
        }
        // Register receiver with proper flags for Android 13+
        val radarFilter = IntentFilter(WearMessageService.ACTION_RADAR)
        val stateFilter = IntentFilter(WearMessageService.ACTION_STATE)
        
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            registerReceiver(receiver, radarFilter, Context.RECEIVER_NOT_EXPORTED)
            registerReceiver(receiver, stateFilter, Context.RECEIVER_NOT_EXPORTED)
        } else {
            registerReceiver(receiver, radarFilter)
            registerReceiver(receiver, stateFilter)
        }

        setContent {
            MaterialTheme {
                val scope = rememberCoroutineScope()
                val ctx = this@WearMainActivity
                val connected by produceState(initialValue = false) {
                    while (true) {
                        val nodes = Wearable.getNodeClient(ctx).connectedNodes
                        value = try {
                            nodes.await().isNotEmpty()
                        } catch (_: Throwable) {
                            false
                        }
                        delay(5000)
                    }
                }

                val snapshot = snapshotState.value
                val phase = snapshot?.phase ?: "OFF_GAME"
                val team = snapshot?.team ?: "UNKNOWN"
                val mode = snapshot?.mode ?: "NORMAL"
                val timeRemain = snapshot?.timeRemainSec ?: 0
                LaunchedEffect(phase, snapshot?.matchId) {
                    Log.d(
                        "WatchBridge",
                        "[WATCH][WEAROS][RX] PHASE matchId=${snapshot?.matchId} phase=$phase"
                    )
                }

                Surface(color = Color(0xFF0E1426)) {
                    Column(
                        modifier = Modifier
                            .fillMaxSize()
                            .padding(12.dp)
                    ) {
                        ConnectionPill(connected = connected)
                        Spacer(Modifier.height(8.dp))

                        when (phase) {
                            "LOBBY" -> LobbyView(
                                snapshot = snapshot,
                                team = team,
                                onAction = { action, value ->
                                    scope.launch(Dispatchers.IO) {
                                        sendWatchAction(ctx, action, value, snapshot?.matchId)
                                    }
                                }
                            )
                            "IN_GAME" -> InGameView(
                                snapshot = snapshot,
                                team = team,
                                mode = mode,
                                timeRemainSec = timeRemain,
                                radarState = radarState.value,
                                captureProgress = progressState.value,
                                onAction = { action, value ->
                                    scope.launch(Dispatchers.IO) {
                                        sendWatchAction(ctx, action, value, snapshot?.matchId)
                                    }
                                }
                            )
                            "POST_GAME" -> PostGameView(snapshot = snapshot)
                            else -> OffGameView(
                                snapshot = snapshot,
                                onAction = { action, value ->
                                    scope.launch(Dispatchers.IO) {
                                        sendWatchAction(ctx, action, value, snapshot?.matchId)
                                    }
                                }
                            )
                        }
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

@Composable
private fun ConnectionPill(connected: Boolean) {
    val text = if (connected) "PHONE: Connected" else "PHONE: Off"
    val color = if (connected) Color(0xFF00E5FF) else Color(0xFF6B7A99)
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(4.dp),
        horizontalArrangement = Arrangement.SpaceBetween,
        verticalAlignment = Alignment.CenterVertically
    ) {
        Text(text, color = color, fontSize = MaterialTheme.typography.labelMedium.fontSize)
        Text("WATCH: OK", color = Color(0xFF39FF14), fontSize = MaterialTheme.typography.labelMedium.fontSize)
    }
}

@Composable
private fun OffGameView(
    snapshot: WatchSnapshot?,
    onAction: (String, Any?) -> Unit
) {
    Column(
        modifier = Modifier
            .fillMaxSize()
            .verticalScroll(rememberScrollState()),
        verticalArrangement = Arrangement.spacedBy(10.dp)
    ) {
        Text("내 프로필", fontWeight = FontWeight.SemiBold)
        Text(
            snapshot?.displayName ?: "Player",
            maxLines = 1,
            overflow = TextOverflow.Ellipsis
        )
        Text(
            "경찰/도둑 랭크 요약",
            color = Color(0xFF8FA3C6),
            fontSize = MaterialTheme.typography.bodySmall.fontSize
        )
        Spacer(Modifier.height(4.dp))
        Button(
            modifier = Modifier.fillMaxWidth(),
            onClick = { onAction("OPEN_STATS", null) }
        ) { Text("최근 경기") }
        OutlinedButton(
            modifier = Modifier.fillMaxWidth(),
            onClick = { onAction("OPEN_RULES", null) }
        ) { Text("내 정보") }
    }
}

@Composable
private fun LobbyView(
    snapshot: WatchSnapshot?,
    team: String,
    onAction: (String, Any?) -> Unit
) {
    var ready by remember { mutableStateOf(false) }
    Column(
        modifier = Modifier
            .fillMaxSize()
            .verticalScroll(rememberScrollState()),
        verticalArrangement = Arrangement.spacedBy(10.dp)
    ) {
        TeamTag(team = team)
        Button(
            modifier = Modifier.fillMaxWidth().height(48.dp),
            onClick = {
                ready = !ready
                onAction("READY_TOGGLE", ready)
            }
        ) { Text(if (ready) "READY ✓" else "READY") }

        Text("규칙 요약", fontWeight = FontWeight.SemiBold)
        Text(snapshot?.rulesLiteText() ?: "규칙 정보 없음", fontSize = MaterialTheme.typography.bodySmall.fontSize)
        Text("참가자 요약", fontWeight = FontWeight.SemiBold)
        Text(snapshot?.countsText() ?: "인원 정보 없음", fontSize = MaterialTheme.typography.bodySmall.fontSize)
    }
}

@Composable
private fun InGameView(
    snapshot: WatchSnapshot?,
    team: String,
    mode: String,
    timeRemainSec: Int,
    radarState: String,
    captureProgress: Float?,
    onAction: (String, Any?) -> Unit
) {
    var tab by remember { mutableStateOf(0) }
    Column(modifier = Modifier.fillMaxSize()) {
        Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
            Text(formatTime(timeRemainSec), fontWeight = FontWeight.Bold)
            ModeTag(mode = mode)
        }
        if (team == "THIEF" && snapshot?.nearbyEnemy == true) {
            Text("DANGER", color = Color(0xFFFF3B30), fontWeight = FontWeight.Bold)
        }
        Spacer(Modifier.height(6.dp))
        Row(horizontalArrangement = Arrangement.spacedBy(6.dp)) {
            OutlinedButton(onClick = { tab = 0 }) { Text("Radar") }
            OutlinedButton(onClick = { tab = 1 }) { Text("Rules") }
            OutlinedButton(onClick = { tab = 2 }) { Text("Stats") }
            OutlinedButton(onClick = { tab = 3 }) { Text("Heart") }
        }
        Spacer(Modifier.height(8.dp))
        when (tab) {
            0 -> {
                Text("Radar", fontWeight = FontWeight.SemiBold)
                Text(radarState)
                if (captureProgress != null) {
                    LinearProgressIndicator(progress = { captureProgress })
                }
            }
            1 -> {
                Text("Rules", fontWeight = FontWeight.SemiBold)
                Text(snapshot?.rulesLiteText() ?: "규칙 정보 없음", fontSize = MaterialTheme.typography.bodySmall.fontSize)
            }
            2 -> {
                Text("Stats", fontWeight = FontWeight.SemiBold)
                Text(snapshot?.countsText() ?: "카운트 없음", fontSize = MaterialTheme.typography.bodySmall.fontSize)
            }
            else -> {
                Text("Heart", fontWeight = FontWeight.SemiBold)
                Text("HR: ${snapshot?.myHr ?: "-"}")
            }
        }
        Spacer(Modifier.height(8.dp))
        Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            OutlinedButton(onClick = { onAction("OPEN_RULES", null) }) { Text("Rules") }
            OutlinedButton(onClick = { onAction("OPEN_STATS", null) }) { Text("Stats") }
        }
    }
}

@Composable
private fun PostGameView(snapshot: WatchSnapshot?) {
    Column(
        modifier = Modifier
            .fillMaxSize()
            .verticalScroll(rememberScrollState()),
        verticalArrangement = Arrangement.spacedBy(10.dp)
    ) {
        Text("POST GAME", fontWeight = FontWeight.SemiBold)
        Text("거리: ${snapshot?.myDistanceM ?: 0}m")
        Text("체포: ${snapshot?.myCaptures ?: 0}")
        Text("구출: ${snapshot?.myRescues ?: 0}")
        Text("탈출: ${snapshot?.myEscapeSec ?: 0}s")
        Text("HR: ${snapshot?.myHr ?: "-"}")
    }
}

@Composable
private fun TeamTag(team: String) {
    val color = when (team) {
        "POLICE" -> Color(0xFF00E5FF)
        "THIEF" -> Color(0xFFFF3B30)
        else -> Color(0xFF6B7A99)
    }
    Text(team, color = color, fontWeight = FontWeight.Bold)
}

@Composable
private fun ModeTag(mode: String) {
    val color = when (mode) {
        "ITEM" -> Color(0xFFB026FF)
        "ABILITY" -> Color(0xFFFFD60A)
        else -> Color(0xFF00E5FF)
    }
    Text(mode, color = color, fontWeight = FontWeight.Bold)
}

private fun formatTime(sec: Int): String {
    val m = sec / 60
    val s = sec % 60
    return "%02d:%02d".format(m, s)
}

private suspend fun sendWatchAction(
    ctx: Context,
    action: String,
    value: Any?,
    matchId: String?
) {
    val payload = JSONObject().apply {
        put("type", "WATCH_ACTION")
        put("ts", System.currentTimeMillis())
        put("matchId", matchId ?: "local")
        put("payload", JSONObject().apply {
            put("action", action)
            put("value", value)
        })
    }
    val json = payload.toString()
    val nodes = Wearable.getNodeClient(ctx).connectedNodes
    val bytes = json.toByteArray(Charsets.UTF_8)
    try {
        val list = nodes.await()
        for (n in list) {
            Wearable.getMessageClient(ctx)
                .sendMessage(n.id, "/gyeongdo/action", bytes)
                .await()
        }
        Log.d(
            "WatchBridge",
            "[WATCH][WEAROS][TX] WATCH_ACTION matchId=$matchId len=${json.length}"
        )
    } catch (_: Throwable) { }
}

private data class WatchSnapshot(
    val phase: String,
    val team: String,
    val mode: String,
    val timeRemainSec: Int,
    val matchId: String?,
    val nearbyEnemy: Boolean,
    val counts: JSONObject?,
    val rulesLite: JSONObject?,
    val my: JSONObject?
) {
    val displayName: String? = null
    val myDistanceM: Int? = my?.optInt("distanceM")
    val myCaptures: Int? = my?.optInt("captures")
    val myRescues: Int? = my?.optInt("rescues")
    val myEscapeSec: Int? = my?.optInt("escapeSec")
    val myHr: Int? = if (my?.isNull("hr") == false) my.optInt("hr") else null

    fun countsText(): String {
        val police = counts?.optInt("police") ?: 0
        val thiefAlive = counts?.optInt("thiefAlive") ?: 0
        val thiefCaptured = counts?.optInt("thiefCaptured") ?: 0
        return "경찰 $police / 도둑생존 $thiefAlive / 체포 $thiefCaptured"
    }

    fun rulesLiteText(): String {
        if (rulesLite == null) return "규칙 없음"
        val contactMode = rulesLite.optString("contactMode")
        val releaseScope = rulesLite.optString("releaseScope")
        val releaseOrder = rulesLite.optString("releaseOrder")
        val jailEnabled = rulesLite.optBoolean("jailEnabled")
        val jailRadius = rulesLite.optInt("jailRadiusM")
        val zonePoints = rulesLite.optInt("zonePoints")
        return "접촉:$contactMode, 해방:$releaseScope/$releaseOrder, 감옥:${if (jailEnabled) "ON" else "OFF"} ${jailRadius}m, 점:$zonePoints"
    }

    companion object {
        fun fromJson(json: String): WatchSnapshot {
            val obj = JSONObject(json)
            val payload = obj.optJSONObject("payload") ?: JSONObject()
            val nearby = payload.optJSONObject("nearby")
            return WatchSnapshot(
                phase = payload.optString("phase", "OFF_GAME"),
                team = payload.optString("team", "UNKNOWN"),
                mode = payload.optString("mode", "NORMAL"),
                timeRemainSec = payload.optInt("timeRemainSec", 0),
                matchId = obj.optString("matchId", null),
                nearbyEnemy = nearby?.optBoolean("enemyNear") ?: false,
                counts = payload.optJSONObject("counts"),
                rulesLite = payload.optJSONObject("rulesLite"),
                my = payload.optJSONObject("my")
            )
        }
    }
}
