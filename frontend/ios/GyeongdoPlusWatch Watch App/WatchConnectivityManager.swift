import Foundation
import WatchConnectivity
import Combine
import WatchKit

struct RadarPing: Codable, Identifiable {
    let id = UUID()
    let kind: String
    let bearingDeg: Double
    let distanceM: Double
    let confidence: Double?
}

struct RadarPacket: Codable {
    let headingDeg: Double
    let ttlMs: Int
    let pings: [RadarPing]
    let captureProgress01: Double?
    let warningDirectionDeg: Double?
}

struct StateSnapshotEnvelope: Codable {
    let type: String
    let ts: Int
    let matchId: String
    let payload: StateSnapshotPayload
}

struct StateSnapshotPayload: Codable {
    let phase: String
    let activeTab: String?
    let team: String
    let mode: String
    let timeRemainSec: Int
    let counts: SnapshotCounts
    let my: SnapshotMy
    let profile: SnapshotProfile?
    let rulesLite: SnapshotRulesLite
    let nearby: SnapshotNearby
    let modeOptions: [String: String]?
}

struct SnapshotProfile: Codable {
    let nickname: String
    let policeRank: String
    let thiefRank: String
    let isReady: Bool
}

struct SnapshotCounts: Codable {
    let police: Int
    let thiefAlive: Int
    let thiefCaptured: Int
    let rescueRate: Double
}

struct SnapshotMy: Codable {
    let distanceM: Int
    let captures: Int
    let rescues: Int
    let escapeSec: Int
    let hr: Int?
    let hrMax: Int?
}

struct SnapshotRulesLite: Codable {
    let contactMode: String
    let releaseScope: String
    let releaseOrder: String
    let jailEnabled: Bool
    let jailRadiusM: Int?
    let zonePoints: Int
}

struct SnapshotNearby: Codable {
    let allyCount10m: Int?
    let enemyNear: Bool?
}

struct HapticEnvelope: Codable {
    let type: String
    let ts: Int
    let matchId: String
    let payload: HapticPayload
}

struct HapticPayload: Codable {
    let kind: String
    let cooldownSec: Int
    let durationMs: Int
}

final class WatchConnectivityManager: NSObject, ObservableObject, WCSessionDelegate {
    @Published var latest: RadarPacket? = nil
    @Published var snapshot: StateSnapshotEnvelope? = nil
    @Published var isReachable: Bool = false
    static let shared = WatchConnectivityManager()

    private var lastHapticByKind: [String: Int] = [:]

    func setup() {
        guard WCSession.isSupported() else { return }
        let s = WCSession.default
        s.delegate = self
        s.activate()
    }

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        print("[WatchWC] activationDidComplete state=\(activationState.rawValue) error=\(String(describing: error))")
        DispatchQueue.main.async {
            switch activationState {
            case .activated:
                self.isReachable = session.isReachable
                print("[WatchWC] Session activated, reachable=\(session.isReachable)")
            case .inactive, .notActivated:
                self.isReachable = false
            @unknown default:
                break
            }
        }
    }
    func sessionReachabilityDidChange(_ session: WCSession) {
        DispatchQueue.main.async {
            self.isReachable = session.isReachable
        }
    }

    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        handle(message: message)
    }

    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        handle(message: applicationContext)
    }

    private func handle(message: [String: Any]) {
        guard let type = message["type"] as? String,
              let json = message["json"] as? String,
              let data = json.data(using: .utf8) else { return }

        switch type {
        case "RADAR_PACKET":
            if let decoded = try? JSONDecoder().decode(RadarPacket.self, from: data) {
                DispatchQueue.main.async {
                    self.latest = decoded
                }
            }
        case "STATE_SNAPSHOT":
            if let decoded = try? JSONDecoder().decode(StateSnapshotEnvelope.self, from: data) {
                DispatchQueue.main.async {
                    self.snapshot = decoded
                }
            }
        case "HAPTIC_ALERT":
            if let decoded = try? JSONDecoder().decode(HapticEnvelope.self, from: data) {
                handleHaptic(decoded)
            }
        default:
            break
        }
    }

    private func handleHaptic(_ env: HapticEnvelope) {
        let now = Int(Date().timeIntervalSince1970 * 1000)
        let kind = env.payload.kind
        let cooldownMs = max(0, env.payload.cooldownSec * 1000)
        let last = lastHapticByKind[kind] ?? 0
        if now - last < cooldownMs { return }
        lastHapticByKind[kind] = now

        let device = WKInterfaceDevice.current()
        device.play(.notification)
    }

    func sendAction(action: String, value: Any?) {
        guard WCSession.isSupported() else { return }
        let s = WCSession.default
        let payload: [String: Any] = [
            "type": "WATCH_ACTION",
            "ts": Int(Date().timeIntervalSince1970 * 1000),
            "matchId": snapshot?.matchId ?? "MATCH_DEMO",
            "payload": [
                "action": action,
                "value": value ?? NSNull()
            ]
        ]
        if s.isReachable {
            s.sendMessage(payload, replyHandler: nil) { error in
                print("[WatchWC] sendMessage error: \(error.localizedDescription)")
            }
        } else {
            do {
                try s.updateApplicationContext(payload)
                print("[WatchWC] updateApplicationContext success action=\(action)")
            } catch {
                print("[WatchWC] updateApplicationContext error: \(error.localizedDescription)")
            }
        }
    }
}
