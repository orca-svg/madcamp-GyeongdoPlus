import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import com.example.frontend.watch.WearBridge
import com.google.android.gms.wearable.MessageClient
import com.google.android.gms.wearable.MessageEvent
import com.google.android.gms.wearable.Wearable

class MainActivity: FlutterActivity() {
    private val channelName = "gyeongdo/watch_bridge"
    private val actionChannelName = "gyeongdo/watch_action"

    private var actionSink: EventChannel.EventSink? = null
    private var messageClient: MessageClient? = null
    private val messageListener = MessageClient.OnMessageReceivedListener { event: MessageEvent ->
        if (event.path == "/gyeongdo/action") {
            val json = String(event.data, Charsets.UTF_8)
            runOnUiThread {
                actionSink?.success(json)
            }
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        val bridge = WearBridge(this)

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, actionChannelName)
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    actionSink = events
                }

                override fun onCancel(arguments: Any?) {
                    actionSink = null
                }
            })

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "init" -> {
                        result.success(true)
                    }
                    "isConnected" -> {
                        CoroutineScope(Dispatchers.IO).launch {
                            try {
                                val connected = bridge.isConnected()
                                withContext(Dispatchers.Main) { result.success(connected) }
                            } catch (e: Exception) {
                                withContext(Dispatchers.Main) { result.success(false) }
                            }
                        }
                    }
                    "sendRadarPacket" -> {
                        val json = (call.arguments as? Map<*, *>)?.get("json") as? String
                        if (json == null) {
                            result.success(false)
                            return@setMethodCallHandler
                        }
                        CoroutineScope(Dispatchers.IO).launch {
                            try {
                                bridge.sendRadarPacket(json)
                                withContext(Dispatchers.Main) { result.success(true) }
                            } catch (e: Exception) {
                                withContext(Dispatchers.Main) { result.success(false) }
                            }
                        }
                    }
                    "sendStateSnapshot" -> {
                        val json = (call.arguments as? Map<*, *>)?.get("json") as? String
                        if (json == null) {
                            result.success(false)
                            return@setMethodCallHandler
                        }
                        CoroutineScope(Dispatchers.IO).launch {
                            try {
                                bridge.sendStateSnapshot(json)
                                withContext(Dispatchers.Main) { result.success(true) }
                            } catch (e: Exception) {
                                withContext(Dispatchers.Main) { result.success(false) }
                            }
                        }
                    }
                    "sendHapticAlert" -> {
                        val json = (call.arguments as? Map<*, *>)?.get("json") as? String
                        if (json == null) {
                            result.success(false)
                            return@setMethodCallHandler
                        }
                        CoroutineScope(Dispatchers.IO).launch {
                            try {
                                bridge.sendHapticAlert(json)
                                withContext(Dispatchers.Main) { result.success(true) }
                            } catch (e: Exception) {
                                withContext(Dispatchers.Main) { result.success(false) }
                            }
                        }
                    }
                    else -> result.notImplemented()
                }
            }

        messageClient = Wearable.getMessageClient(this).also {
            it.addListener(messageListener)
        }
    }

    override fun onDestroy() {
        messageClient?.removeListener(messageListener)
        messageClient = null
        super.onDestroy()
    }
}
