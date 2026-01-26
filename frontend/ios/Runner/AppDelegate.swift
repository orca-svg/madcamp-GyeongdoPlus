import UIKit
import Flutter

@main

@objc class AppDelegate: FlutterAppDelegate {
  /// Idempotent guard: WatchBridge 초기화가 한 번만 실행되도록 함
  private var watchBridgeInitialized = false

  /// WatchBridge 초기화 지연 시간 (초) - F
  // lutter 엔진/플러그인 등록 완료 대기
  private let watchBridgeDelaySeconds: Double = 1.0

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    NSLog("[IOS][APPDELEGATE] didFinishLaunching START")

    // ============================================================
    // 1. super.application() 반드시 가장 먼저 호출
    //    - 내부적으로 GeneratedPluginRegistrant.register 수행
    //    - 명시적 register 추가 금지 (중복 등록 → instanceManager 충돌)
    // ============================================================
    NSLog("[IOS][APPDELEGATE] super.application BEFORE")
    let result = super.application(application, didFinishLaunchingWithOptions: launchOptions)
    NSLog("[IOS][APPDELEGATE] super.application AFTER (result=\(result))")

    // ============================================================
    // 2. WatchBridge 비활성화 플래그 (UserDefaults 기반 런타임 스위치)
    //    - key: "DISABLE_WATCH_BRIDGE" → true면 비활성
    //    - 기본값: false (Watch ON)
    // ============================================================
    let disableWatch = UserDefaults.standard.bool(forKey: "DISABLE_WATCH_BRIDGE")

    if disableWatch {
      NSLog("[IOS][WATCH] WatchBridge DISABLED via UserDefaults")
    } else {
      // ============================================================
      // 3. WatchBridge 초기화를 "Flutter 첫 프레임 이후"로 지연
      //    - 앱 시작 직후 즉시 초기화하면 엔진/플러그인 등록 타이밍 교란
      //    - DispatchQueue.main.asyncAfter로 지연하여 안전한 시점에 수행
      // ============================================================
      NSLog("[IOS][WATCH] scheduling init after \(watchBridgeDelaySeconds)s delay...")
      DispatchQueue.main.asyncAfter(deadline: .now() + watchBridgeDelaySeconds) { [weak self] in
        self?.initializeWatchBridge()
      }
    }

    NSLog("[IOS][APPDELEGATE] didFinishLaunching END")
    return result
  }

  /// WatchBridge 초기화 및 MethodChannel 설정 (지연 실행, idempotent)
  private func initializeWatchBridge() {
    // Idempotent guard: 두 번 호출 방지
    guard !watchBridgeInitialized else {
      NSLog("[IOS][WATCH] init SKIPPED (already initialized)")
      return
    }
    watchBridgeInitialized = true

    NSLog("[IOS][WATCH] init START")

    // WatchBridge.setup() 호출
    NSLog("[IOS][WATCH] WatchBridge.setup BEFORE")
    WatchBridge.shared.setup()
    NSLog("[IOS][WATCH] WatchBridge.setup AFTER")

    // FlutterViewController 접근하여 MethodChannel 설정
    guard let controller = window?.rootViewController as? FlutterViewController else {
      NSLog("[IOS][WATCH] WARNING: FlutterViewController not found - channel NOT created")
      return
    }

    NSLog("[IOS][WATCH] FlutterViewController found, setting up channel")
    let channel = FlutterMethodChannel(name: "gyeongdo/watch_bridge", binaryMessenger: controller.binaryMessenger)

    channel.setMethodCallHandler { call, callResult in
      switch call.method {
      case "init":
        WatchBridge.shared.setup()
        callResult(true)

      case "isConnected":
        callResult(WatchBridge.shared.isConnected())

      case "sendRadarPacket":
        if let args = call.arguments as? [String: Any],
           let json = args["json"] as? String {
          WatchBridge.shared.sendRadarPacket(json: json)
          callResult(true)
        } else {
          callResult(false)
        }

      default:
        callResult(FlutterMethodNotImplemented)
      }
    }

    NSLog("[IOS][WATCH] channel ready")
    NSLog("[IOS][WATCH] init END")
  }
}
