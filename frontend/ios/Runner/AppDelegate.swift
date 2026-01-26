import UIKit
import Flutter

@main

@objc class AppDelegate: FlutterAppDelegate {

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    NSLog("[IOS][APPDELEGATE] didFinishLaunching START")
    NSLog("[IOS][APP] bundle=\(Bundle.main.bundleIdentifier ?? "nil")")

    // ============================================================
    // 1. super.application() 반드시 가장 먼저 호출
    // ============================================================
    NSLog("[IOS][APPDELEGATE] super.application BEFORE")
    let result = super.application(application, didFinishLaunchingWithOptions: launchOptions)
    NSLog("[IOS][APPDELEGATE] super.application AFTER (result=\(result))")
    GeneratedPluginRegistrant.register(with: self)
    NSLog("[IOS][APPDELEGATE] registrant done")

    // ============================================================
    // 2. WatchBridge 활성/비활성 정책
    //    - Simulator(iOS)에서는 WebView(Pigeon) 충돌 방지를 위해 강제 OFF
    //    - UserDefaults("DISABLE_WATCH_BRIDGE")는 런타임 스위치로 유지
    // ============================================================
    var watchEnabled = true
    var isSimulator = false
    var simOverride = false
#if targetEnvironment(simulator)
      isSimulator = true
      let env = ProcessInfo.processInfo.environment["ENABLE_WATCH_BRIDGE_SIM"]
      let envOverride = (env == "1" || env == "true" || env == "YES")
      simOverride = envOverride || UserDefaults.standard.bool(forKey: "ENABLE_WATCH_BRIDGE_SIM")
      watchEnabled = simOverride
#endif

    if UserDefaults.standard.bool(forKey: "DISABLE_WATCH_BRIDGE") {
      watchEnabled = false
      NSLog("[IOS][WATCH] WatchBridge disabled via UserDefaults")
    }
    NSLog("[IOS][WATCH] enabled=\(watchEnabled) simulator=\(isSimulator) simOverride=\(simOverride)")

    // ============================================================
    // 3. WatchBridgePlugin 등록 (Method/Event Channel)
    // ============================================================
    WatchBridgePlugin.watchEnabled = watchEnabled
    if let registrar = self.registrar(forPlugin: "WatchBridgePlugin") {
      WatchBridgePlugin.register(with: registrar)
      NSLog("[IOS][WATCH] WatchBridgePlugin registered")
    } else {
      NSLog("[IOS][WATCH] WARNING: registrar not found for WatchBridgePlugin")
    }

    NSLog("[IOS][APPDELEGATE] didFinishLaunching END")
    return result
  }

}
