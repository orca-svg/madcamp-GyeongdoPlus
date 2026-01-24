import Foundation
import WatchConnectivity
import Combine

struct RadarPing: Codable, Identifiable {
    let id = UUID()
    let kind: String
    let bearingDeg: Double
    let distanceM: Double
    let confidence: Double
}

struct RadarPacket: Codable {
    let headingDeg: Double
    let ttlMs: Int
    let pings: [RadarPing]
    let captureProgress01: Double?
    let warningDirectionDeg: Double?
}

final class WatchConnectivityManager: NSObject, ObservableObject, WCSessionDelegate {
    @Published var latest: RadarPacket? = nil
    static let shared = WatchConnectivityManager()

    func setup() {
        guard WCSession.isSupported() else { return }
        let s = WCSession.default
        s.delegate = self
        s.activate()
    }

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {}

    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        handle(message: message)
    }

    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        handle(message: applicationContext)
    }

    private func handle(message: [String: Any]) {
        guard let type = message["type"] as? String, type == "radar_packet",
              let json = message["json"] as? String,
              let data = json.data(using: .utf8)
        else { return }

        if let decoded = try? JSONDecoder().decode(RadarPacket.self, from: data) {
            DispatchQueue.main.async {
                self.latest = decoded
            }
        }
    }
}
