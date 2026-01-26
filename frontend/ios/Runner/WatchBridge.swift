import Foundation
import WatchConnectivity
import Flutter
import UIKit

final class WatchBridge: NSObject, WCSessionDelegate {
    static let shared = WatchBridge()

    var actionHandler: (([String: Any]) -> Void)?

    private var didSetup = false

    private override init() {
        super.init()
    }

    func setup() {
        if didSetup { return }
        didSetup = true
        print("[WatchBridge] setup() called")
        guard WCSession.isSupported() else {
            print("[WatchBridge] WCSession not supported")
            return
        }
        let session = WCSession.default
        session.delegate = self
        session.activate()
    }

    func isConnected() -> Bool {
        guard WCSession.isSupported() else { return false }
        let s = WCSession.default
        let ok = s.isPaired && s.isWatchAppInstalled
        print("[WatchBridge] isConnected paired=\(s.isPaired) installed=\(s.isWatchAppInstalled) reachable=\(s.isReachable) -> \(ok)")
        return ok
    }

    func sendRadarPacket(json: String) {
        print("[WatchBridge] sendRadarPacket len=\(json.count)")
        sendMessage(type: "RADAR_PACKET", json: json)
    }

    func sendStateSnapshot(json: String) {
        print("[WatchBridge] sendStateSnapshot len=\(json.count)")
        sendMessage(type: "STATE_SNAPSHOT", json: json)
    }

    func sendHapticAlert(json: String) {
        print("[WatchBridge] sendHapticAlert len=\(json.count)")
        sendMessage(type: "HAPTIC_ALERT", json: json)
    }

    private func sendMessage(type: String, json: String) {
        guard WCSession.isSupported() else { return }
        let s = WCSession.default

        let payload: [String: Any] = [
            "type": type,
            "json": json,
            "ts": Int(Date().timeIntervalSince1970 * 1000)
        ]
        if s.isReachable {
            s.sendMessage(payload, replyHandler: nil, errorHandler: nil)
        } else {
            // reachable이 아니면 applicationContext로 “최신값” 전달(워치가 나중에 열어도 반영)
            try? s.updateApplicationContext(payload)
        }
    }

    // MARK: WCSessionDelegate
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {}
    func sessionDidBecomeInactive(_ session: WCSession) {}
    func sessionDidDeactivate(_ session: WCSession) { WCSession.default.activate() }

    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        actionHandler?(message)
    }
}

@objc
public class WatchBridgePlugin: NSObject, FlutterPlugin, FlutterStreamHandler {
    public static var watchEnabled: Bool = true

    private var eventSink: FlutterEventSink?
    private var sessionSetup = false

    public static func register(with registrar: FlutterPluginRegistrar) {
        let instance = WatchBridgePlugin()
        let methodChannel = FlutterMethodChannel(
            name: "gyeongdo/watch_bridge",
            binaryMessenger: registrar.messenger()
        )
        registrar.addMethodCallDelegate(instance, channel: methodChannel)

        let eventChannel = FlutterEventChannel(
            name: "gyeongdo/watch_action",
            binaryMessenger: registrar.messenger()
        )
        eventChannel.setStreamHandler(instance)

        WatchBridge.shared.actionHandler = { payload in
            guard let sink = instance.eventSink else { return }
            if let data = try? JSONSerialization.data(withJSONObject: payload, options: []),
               let json = String(data: data, encoding: .utf8) {
                sink(json)
            } else {
                sink(payload)
            }
        }
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "init":
            guard WatchBridgePlugin.watchEnabled else {
                result(false)
                return
            }
            if !sessionSetup {
                sessionSetup = true
                WatchBridge.shared.setup()
            }
            result(true)

        case "isConnected":
            guard WatchBridgePlugin.watchEnabled, sessionSetup else {
                result(false)
                return
            }
            result(WatchBridge.shared.isConnected())

        case "sendRadarPacket":
            guard WatchBridgePlugin.watchEnabled, sessionSetup else {
                result(false)
                return
            }
            if let args = call.arguments as? [String: Any],
               let json = args["json"] as? String {
                WatchBridge.shared.sendRadarPacket(json: json)
                result(true)
            } else {
                result(false)
            }

        case "sendStateSnapshot":
            guard WatchBridgePlugin.watchEnabled, sessionSetup else {
                result(false)
                return
            }
            if let args = call.arguments as? [String: Any],
               let json = args["json"] as? String {
                WatchBridge.shared.sendStateSnapshot(json: json)
                result(true)
            } else {
                result(false)
            }

        case "sendHapticAlert":
            guard WatchBridgePlugin.watchEnabled, sessionSetup else {
                result(false)
                return
            }
            if let args = call.arguments as? [String: Any],
               let json = args["json"] as? String {
                WatchBridge.shared.sendHapticAlert(json: json)
                result(true)
            } else {
                result(false)
            }

        case "sendHaptic":
            result(false)

        default:
            result(FlutterMethodNotImplemented)
        }
    }

    public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        eventSink = events
        return nil
    }

    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        eventSink = nil
        return nil
    }
}
