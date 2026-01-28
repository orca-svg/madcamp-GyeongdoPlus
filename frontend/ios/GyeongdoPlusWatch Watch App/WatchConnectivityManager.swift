import Foundation
import WatchConnectivity
import Combine
import WatchKit
import HealthKit
import CoreLocation

struct RadarPing: Codable, Identifiable {
    var id = UUID()
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
    let skill: SnapshotSkill?
}

struct SnapshotSkill: Codable {
    let type: String
    let label: String
    let sf: String
    let remain: Int
    let total: Int
    let ready: Bool
}

struct SnapshotRulesLite: Codable {
    let contactMode: String
    let releaseScope: String
    let releaseOrder: String
    let jailEnabled: Bool
    let jailRadiusM: Int?
    let zonePoints: Int
}

struct AllyBlip: Codable, Identifiable {
    var id: String { allyId }
    let d: Double      // distance (meters)
    let b: Double      // relative bearing (degrees, -180 ~ 180)
    let allyId: String // player ID (first 4 chars)

    enum CodingKeys: String, CodingKey {
        case d
        case b
        case allyId = "id"
    }
}

struct SnapshotNearby: Codable {
    let allyCount10m: Int?
    let enemyNear: Bool?
    let allies: [AllyBlip]?
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

final class WatchConnectivityManager: NSObject, ObservableObject, WCSessionDelegate, CLLocationManagerDelegate, HKLiveWorkoutBuilderDelegate {
    @Published var latest: RadarPacket? = nil
    @Published var snapshot: StateSnapshotEnvelope? = nil {
        didSet {
            checkSensorState()
        }
    }
    @Published var isReachable: Bool = false
    @Published var currentHeartRate: Int = 0
    @Published var currentHeading: Double = 0.0
    
    static let shared = WatchConnectivityManager()

    private var lastHapticByKind: [String: Int] = [:]
    
    // Sensors
    private let healthStore = HKHealthStore()
    private let locationManager = CLLocationManager()
    private var session: HKWorkoutSession?
    private var builder: HKLiveWorkoutBuilder?
    private var isSensorActive = false

    override init() {
        super.init()
        setupSensors()
    }

    func setup() {
        guard WCSession.isSupported() else { return }
        let s = WCSession.default
        s.delegate = self
        s.activate()
    }
    
    private func setupSensors() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        
        let types: Set = [HKQuantityType.quantityType(forIdentifier: .heartRate)!]
        healthStore.requestAuthorization(toShare: [], read: types) { success, error in
            print("[WatchWC] HealthKit Auth: \(success)")
        }
    }
    
    // MARK: - Sensor Logic (Battery Efficient)
    private func checkSensorState() {
        guard let phase = snapshot?.payload.phase else { return }
        let shouldBeActive = (phase == "IN_GAME")
        
        if shouldBeActive && !isSensorActive {
            startSensors()
        } else if !shouldBeActive && isSensorActive {
            stopSensors()
        }
    }
    
    private func startSensors() {
        print("[WatchWC] Starting Sensors (HR & Compass)")
        isSensorActive = true
        
        // Compass
        locationManager.startUpdatingHeading()
        
        // Heart Rate (Start Workout Session)
        let config = HKWorkoutConfiguration()
        config.activityType = .running
        config.locationType = .outdoor
        
        do {
            session = try HKWorkoutSession(healthStore: healthStore, configuration: config)
            builder = session?.associatedWorkoutBuilder()
            
            builder?.dataSource = HKLiveWorkoutDataSource(healthStore: healthStore, workoutConfiguration: config)
            session?.delegate = nil // Simple usage
            builder?.delegate = self
            
            session?.startActivity(with: Date())
            builder?.beginCollection(withStart: Date()) { success, error in
                print("[WatchWC] Workout Session Started: \(success)")
            }
        } catch {
            print("[WatchWC] HK Session Error: \(error)")
        }
    }
    
    private func stopSensors() {
        print("[WatchWC] Stopping Sensors")
        isSensorActive = false
        
        locationManager.stopUpdatingHeading()
        
        session?.end()
        builder?.endCollection(withEnd: Date()) { _, _ in }
        session = nil
        builder = nil
    }

    // MARK: - CLLocationManagerDelegate
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        // -180 ~ 180 or 0 ~ 360
        DispatchQueue.main.async {
            self.currentHeading = newHeading.magneticHeading
        }
    }
    
    // MARK: - HKLiveWorkoutBuilderDelegate
    func workoutBuilder(_ workoutBuilder: HKLiveWorkoutBuilder, didCollectDataOf collectedTypes: Set<HKSampleType>) {
        for type in collectedTypes {
            guard let quantityType = type as? HKQuantityType else { continue }
            if quantityType.identifier == HKQuantityTypeIdentifier.heartRate.rawValue {
                let statistics = workoutBuilder.statistics(for: quantityType)
                let heartRateUnit = HKUnit.count().unitDivided(by: HKUnit.minute())
                let value = statistics?.mostRecentQuantity()?.doubleValue(for: heartRateUnit)
                if let value = value {
                    updateHeartRate(value)
                }
            }
        }
    }
    
    func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) {
        // No-op
    }
    
    // MARK: - Heart Rate Update
    func updateHeartRate(_ hr: Double) {
        let bpm = Int(hr)
        DispatchQueue.main.async {
            self.currentHeartRate = bpm
        }
        // Send to Phone
        sendAction(action: "HEART_RATE", value: bpm)
    }

    // MARK: - WCSessionDelegate
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        print("[WatchWC] activationDidComplete state=\(activationState.rawValue) error=\(String(describing: error))")
        DispatchQueue.main.async {
            switch activationState {
            case .activated:
                self.isReachable = session.isReachable
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
        // Heavy Haptic for Thief Warning
        if kind.contains("ENEMY") || kind.contains("NEAR") {
            device.play(.retry) // Stronger than notification
        } else {
            device.play(.notification)
        }
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
            } catch {
                print("[WatchWC] updateApplicationContext error: \(error.localizedDescription)")
            }
        }
    }
}
