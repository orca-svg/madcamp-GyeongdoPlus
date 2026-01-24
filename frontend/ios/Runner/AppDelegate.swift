import UIKit
import Flutter

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {

    WatchBridge.shared.setup()

    let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
    let channel = FlutterMethodChannel(name: "gyeongdo/watch_bridge", binaryMessenger: controller.binaryMessenger)

    channel.setMethodCallHandler { call, result in
      switch call.method {
      case "init":
        WatchBridge.shared.setup()
        result(true)

      case "isConnected":
        result(WatchBridge.shared.isConnected())

      case "sendRadarPacket":
        if let args = call.arguments as? [String: Any],
           let json = args["json"] as? String {
          WatchBridge.shared.sendRadarPacket(json: json)
          result(true)
        } else {
          result(false)
        }

      default:
        result(FlutterMethodNotImplemented)
      }
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
