import UIKit
import Flutter

@main

@objc class AppDelegate: FlutterAppDelegate {

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
    
    NSLog("[IOS][APPDELEGATE] didFinishLaunching START")
    
    // ============================================================
    // 1. super.application() 반드시 가장 먼저 호출
    // ============================================================
    let result = super.application(application, didFinishLaunchingWithOptions: launchOptions)
    
    GeneratedPluginRegistrant.register(with: self)

    // ============================================================
    // 2. WatchBridge 활성/비활성 정책
    // ============================================================
    var watchEnabled = true
    #if targetEnvironment(simulator)
      let env = ProcessInfo.processInfo.environment["ENABLE_WATCH_BRIDGE_SIM"]
      let envOverride = (env == "1" || env == "true" || env == "YES")
      watchEnabled = envOverride || UserDefaults.standard.bool(forKey: "ENABLE_WATCH_BRIDGE_SIM")
    #endif

    if UserDefaults.standard.bool(forKey: "DISABLE_WATCH_BRIDGE") {
      watchEnabled = false
    }
    
    // ============================================================
    // 3. WatchBridgePlugin 등록 (Method/Event Channel)
    // ============================================================
    WatchBridgePlugin.watchEnabled = watchEnabled
    if let registrar = self.registrar(forPlugin: "WatchBridgePlugin") {
      WatchBridgePlugin.register(with: registrar)
    }

    NSLog("[IOS][APPDELEGATE] didFinishLaunching END")
    return result
  }

  // ✅ Kakao Login / Deep Link Handling
  override func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
    NSLog("[IOS][APPDELEGATE] Open URL: \(url.absoluteString)")
    return super.application(app, open: url, options: options)
  }
}
