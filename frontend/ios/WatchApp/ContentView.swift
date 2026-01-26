import SwiftUI

struct ContentView: View {
    @StateObject private var wc = WatchConnectivityManager.shared

    var body: some View {
        Group {
            switch wc.snapshot?.payload.phase {
            case "LOBBY":
                LobbyView()
            case "IN_GAME":
                InGamePagerView()
            case "POST_GAME":
                PostGameView()
            default:
                OffGameView()
            }
        }
        .onAppear { wc.setup() }
    }
}

struct OffGameView: View {
    @StateObject private var wc = WatchConnectivityManager.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ConnectionPill(isConnected: wc.isReachable)
            Spacer().frame(height: 4)
            Text("경도+").font(.system(size: 18, weight: .bold))
            Text("닉네임: \(nickname())")
                .font(.system(size: 12, weight: .semibold))
                .lineLimit(1)
            Text("랭크: 경찰 · 도둑")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.secondary)
                .lineLimit(1)
            Spacer().frame(height: 8)
            LargeButton(title: "최근 경기") {
                wc.sendAction(action: "OPEN_STATS", value: nil)
            }
            LargeButton(title: "내 정보") {
                wc.sendAction(action: "OPEN_RULES", value: nil)
            }
            Spacer()
        }
        .padding()
        .background(Color.black.opacity(0.92))
    }

    private func nickname() -> String {
        return "PLAYER"
    }
}

struct LobbyView: View {
    @StateObject private var wc = WatchConnectivityManager.shared

    var body: some View {
        let payload = wc.snapshot?.payload
        VStack(alignment: .leading, spacing: 10) {
            TeamTag(team: payload?.team ?? "UNKNOWN")
            LargeButton(title: "READY") {
                wc.sendAction(action: "READY_TOGGLE", value: nil)
            }
            SectionCard(title: "규칙") {
                rulesLiteText(payload)
            }
            SectionCard(title: "참가자") {
                HStack {
                    Text("경찰 \(payload?.counts.police ?? 0)")
                    Spacer()
                    Text("도둑 \(payload?.counts.thiefAlive ?? 0)")
                }
                .font(.system(size: 12, weight: .semibold))
            }
            Spacer()
        }
        .padding()
        .background(Color.black.opacity(0.92))
    }

    private func rulesLiteText(_ p: StateSnapshotPayload?) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("모드: \(p?.mode ?? "—")")
            Text("접촉: \(p?.rulesLite.contactMode ?? "—")")
            Text("해방: \(p?.rulesLite.releaseScope ?? "—") \(p?.rulesLite.releaseOrder ?? "")")
        }
        .font(.system(size: 11, weight: .semibold))
        .foregroundColor(.secondary)
    }
}

struct InGamePagerView: View {
    var body: some View {
        TabView {
            InGameRadarView()
            InGameRulesView()
            InGameStatsView()
            InGameHeartView()
        }
        .tabViewStyle(.page)
    }
}

struct InGameRadarView: View {
    @StateObject private var wc = WatchConnectivityManager.shared

    var body: some View {
        let p = wc.snapshot?.payload
        VStack(alignment: .leading, spacing: 10) {
            if (p?.nearby.enemyNear ?? false) && p?.team == "THIEF" {
                DangerPill()
            }
            Text("레이더").font(.system(size: 16, weight: .bold))
            Text("아군 10m: \(p?.nearby.allyCount10m ?? 0)")
                .font(.system(size: 12, weight: .semibold))
            Text("남은 시간: \(p?.timeRemainSec ?? 0)s")
                .font(.system(size: 12, weight: .semibold))
            LargeButton(title: "PING") {
                wc.sendAction(action: "PING", value: nil)
            }
            Spacer()
        }
        .padding()
        .background(Color.black.opacity(0.92))
    }
}

struct InGameRulesView: View {
    @StateObject private var wc = WatchConnectivityManager.shared

    var body: some View {
        let r = wc.snapshot?.payload.rulesLite
        VStack(alignment: .leading, spacing: 10) {
            Text("규칙").font(.system(size: 16, weight: .bold))
            Text("접촉: \(r?.contactMode ?? "—")")
            Text("해방: \(r?.releaseScope ?? "—") \(r?.releaseOrder ?? "")")
            Text("감옥: \(r?.jailEnabled == true ? "ON" : "OFF")")
            Text("반경: \(r?.jailRadiusM ?? 0)m")
            Text("구역 점: \(r?.zonePoints ?? 0)")
            Spacer()
        }
        .font(.system(size: 12, weight: .semibold))
        .foregroundColor(.secondary)
        .padding()
        .background(Color.black.opacity(0.92))
    }
}

struct InGameStatsView: View {
    @StateObject private var wc = WatchConnectivityManager.shared

    var body: some View {
        let p = wc.snapshot?.payload
        VStack(alignment: .leading, spacing: 10) {
            Text("현황").font(.system(size: 16, weight: .bold))
            Text("경찰: \(p?.counts.police ?? 0)")
            Text("도둑 생존: \(p?.counts.thiefAlive ?? 0)")
            Text("도둑 체포: \(p?.counts.thiefCaptured ?? 0)")
            Text("시간: \(p?.timeRemainSec ?? 0)s")
            Spacer()
        }
        .font(.system(size: 12, weight: .semibold))
        .foregroundColor(.secondary)
        .padding()
        .background(Color.black.opacity(0.92))
    }
}

struct InGameHeartView: View {
    @StateObject private var wc = WatchConnectivityManager.shared

    var body: some View {
        let hr = wc.snapshot?.payload.my.hr
        VStack(alignment: .leading, spacing: 10) {
            Text("심박").font(.system(size: 16, weight: .bold))
            Text(hr != nil ? "\(hr!) bpm" : "—")
                .font(.system(size: 20, weight: .bold))
            Spacer()
        }
        .padding()
        .background(Color.black.opacity(0.92))
    }
}

struct PostGameView: View {
    @StateObject private var wc = WatchConnectivityManager.shared

    var body: some View {
        let p = wc.snapshot?.payload
        VStack(alignment: .leading, spacing: 10) {
            Text("결과").font(.system(size: 16, weight: .bold))
            if p?.team == "POLICE" {
                Text("체포: \(p?.my.captures ?? 0)")
            } else {
                Text("해방: \(p?.my.rescues ?? 0)")
            }
            Text("이동: \(p?.my.distanceM ?? 0)m")
            Text("탈출: \(p?.my.escapeSec ?? 0)s")
            Spacer()
        }
        .font(.system(size: 12, weight: .semibold))
        .foregroundColor(.secondary)
        .padding()
        .background(Color.black.opacity(0.92))
    }
}

struct ConnectionPill: View {
    let isConnected: Bool

    var body: some View {
        HStack {
            Circle()
                .fill(isConnected ? Color.green : Color.gray)
                .frame(width: 6, height: 6)
            Text(isConnected ? "PHONE: Connected" : "PHONE: Off")
                .font(.system(size: 10, weight: .bold))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.black.opacity(0.6))
        .clipShape(Capsule())
    }
}

struct TeamTag: View {
    let team: String
    var body: some View {
        let color: Color = team == "POLICE" ? Color.cyan : (team == "THIEF" ? Color.red : Color.gray)
        Text(team)
            .font(.system(size: 11, weight: .bold))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(color.opacity(0.15))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(color.opacity(0.55), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

struct DangerPill: View {
    var body: some View {
        Text("DANGER")
            .font(.system(size: 11, weight: .bold))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color.red.opacity(0.2))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.red.opacity(0.7), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

struct LargeButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 13, weight: .bold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(Color.blue.opacity(0.7))
                .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
    }
}

struct SectionCard<Content: View>: View {
    let title: String
    let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 12, weight: .bold))
            content()
        }
        .padding(10)
        .background(Color.white.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}
