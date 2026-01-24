import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import com.example.frontend.watch.WearBridge

class MainActivity: FlutterActivity() {
    private val channelName = "gyeongdo/watch_bridge"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        val bridge = WearBridge(this)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "init" -> {
                        result.success(true)
                    }
                    "isConnected" -> {
                        CoroutineScope(Dispatchers.Main).launch {
                            result.success(bridge.isConnected())
                        }
                    }
                    "sendRadarPacket" -> {
                        val json = (call.arguments as? Map<*, *>)?.get("json") as? String
                        if (json == null) {
                            result.success(false)
                            return@setMethodCallHandler
                        }
                        CoroutineScope(Dispatchers.Main).launch {
                            bridge.sendRadarPacket(json)
                            result.success(true)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
