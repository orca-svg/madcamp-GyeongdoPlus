import UIKit
import Flutter

@main

@objc class AppDelegate: FlutterAppDelegate {
  /// Idempotent guard: MethodChannel 설정이 한 번만 실행되도록 함
  private var watchChannelInitialized = false

  /// Idempotent guard: WCSession setup이 한 번만 실행되도록 함
  private var watchSessionSetup = false

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    NSLog("[IOS][APPDELEGATE] didFinishLaunching START")
    NSLog("[IOS][APP] bundle=\(Bundle.main.bundleIdentifier ?? "nil")")

    // ============================================================
    // 1. super.application() 반드시 가장 먼저 호출
    //    - 내부적으로 GeneratedPluginRegistrant.register 수행
    //    - 명시적 register 추가 금지 (중복 등록 → instanceManager 충돌)
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
#if targetEnvironment(simulator)
    watchEnabled = false
    NSLog("[IOS][WATCH] WatchBridge disabled (simulator)")
#endif

    if UserDefaults.standard.bool(forKey: "DISABLE_WATCH_BRIDGE") {
      watchEnabled = false
      NSLog("[IOS][WATCH] WatchBridge disabled via UserDefaults")
    }

    // ============================================================
    // 3. MethodChannel은 항상 준비 (Dart에서 MissingPluginException 방지)
    //    - 단, WCSession 활성화(setup)는 Dart 'init' 호출 시에만 수행
    // ============================================================
    initializeWatchChannel(watchEnabled: watchEnabled)

    NSLog("[IOS][APPDELEGATE] didFinishLaunching END")
    return result
  }

  /// MethodChannel 설정 (idempotent). WCSession setup은 'init'에서만.
  private func initializeWatchChannel(watchEnabled: Bool) {
    guard !watchChannelInitialized else { return }
    watchChannelInitialized = true

    guard let controller = window?.rootViewController as? FlutterViewController else {
      NSLog("[IOS][WATCH] WARNING: FlutterViewController not found - channel NOT created")
      return
    }

    NSLog("[IOS][WATCH] FlutterViewController found, setting up channel")
    let channel = FlutterMethodChannel(name: "gyeongdo/watch_bridge", binaryMessenger: controller.binaryMessenger)

    channel.setMethodCallHandler { call, callResult in
      switch call.method {
      case "init":
        guard watchEnabled else {
          callResult(false)
          return
        }

        // WCSession setup은 여기서만 실행 (WebView 초기화 타이밍과 분리)
        if !self.watchSessionSetup {
          self.watchSessionSetup = true
          NSLog("[IOS][WATCH] WatchBridge.setup (from Dart init) BEFORE")
          WatchBridge.shared.setup()
          NSLog("[IOS][WATCH] WatchBridge.setup (from Dart init) AFTER")
        }
        callResult(true)

      case "isConnected":
        guard watchEnabled, self.watchSessionSetup else {
          callResult(false)
          return
        }
        callResult(WatchBridge.shared.isConnected())

      case "sendRadarPacket":
        guard watchEnabled, self.watchSessionSetup else {
          callResult(false)
          return
        }
        if let args = call.arguments as? [String: Any],
           let json = args["json"] as? String {
          WatchBridge.shared.sendRadarPacket(json: json)
          callResult(true)
        } else {
          callResult(false)
        }

      case "sendHaptic":
        // Not implemented on native yet; return false without throwing.
        callResult(false)

      default:
        callResult(FlutterMethodNotImplemented)
      }
    }

    NSLog("[IOS][WATCH] channel ready")
  }
}
