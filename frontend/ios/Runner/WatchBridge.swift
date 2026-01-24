import Foundation
import WatchConnectivity

final class WatchBridge: NSObject, WCSessionDelegate {
    static let shared = WatchBridge()

    private override init() {
        super.init()
    }

    func setup() {
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

        guard WCSession.isSupported() else { return }
        let s = WCSession.default

        let payload: [String: Any] = ["type": "radar_packet", "json": json, "ts": Int(Date().timeIntervalSince1970 * 1000)]
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
}
