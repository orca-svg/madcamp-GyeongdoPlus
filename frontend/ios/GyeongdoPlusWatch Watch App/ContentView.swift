import SwiftUI
import Combine

struct ContentView: View {
    @StateObject private var wc = WatchConnectivityManager.shared
    @State private var connectionTick = false
    
    // 1초 타이머로 connection dot 갱신
    let connectionTimer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

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
        .onReceive(connectionTimer) { _ in
            connectionTick.toggle() // UI 리프레시 트리거
        }
    }
}

// MARK: - OffGame View (프로필 표시)
struct OffGameView: View {
    @StateObject private var wc = WatchConnectivityManager.shared
    
    // activeTab 기반 탭 선택 (폰 미러링)
    private var selectedIndex: Int {
        guard let activeTab = wc.snapshot?.payload.activeTab else { return 0 }
        switch activeTab {
        case "OFFGAME_HOME": return 0
        case "OFFGAME_RECENT": return 1
        case "OFFGAME_PROFILE": return 2
        default: return 0
        }
    }

    var body: some View {
        let profile = wc.snapshot?.payload.profile
        
        TabView(selection: .constant(selectedIndex)) {
            // Tab 0: Home
            VStack(alignment: .leading, spacing: 10) {
                ConnectionPill(isConnected: wc.isReachable)
                Spacer().frame(height: 4)
                
                Text("경도+")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                
                Text(profile?.nickname ?? "PLAYER")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                HStack(spacing: 8) {
                    RankBadge(label: "경찰", rank: profile?.policeRank ?? "—", color: .cyan)
                    RankBadge(label: "도둑", rank: profile?.thiefRank ?? "—", color: .red)
                }
                
                Spacer()
            }
            .padding()
            .background(Color.black.opacity(0.92))
            .tag(0)
            .onTapGesture {
                // 탭 변경 요청 (폰으로)
                wc.sendAction(action: "OPEN_TAB", value: "OFFGAME_HOME")
            }
            
            // Tab 1: Recent
            VStack(alignment: .leading, spacing: 10) {
                ConnectionPill(isConnected: wc.isReachable)
                Text("최근 경기").font(.system(size: 16, weight: .bold))
                Text("경기 기록이 여기에 표시됩니다")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                Spacer()
            }
            .padding()
            .background(Color.black.opacity(0.92))
            .tag(1)
            .onTapGesture {
                wc.sendAction(action: "OPEN_TAB", value: "OFFGAME_RECENT")
            }
            
            // Tab 2: Profile
            VStack(alignment: .leading, spacing: 10) {
                ConnectionPill(isConnected: wc.isReachable)
                Text("내 정보").font(.system(size: 16, weight: .bold))
                Text("프로필 정보가 여기에 표시됩니다")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                Spacer()
            }
            .padding()
            .background(Color.black.opacity(0.92))
            .tag(2)
            .onTapGesture {
                wc.sendAction(action: "OPEN_TAB", value: "OFFGAME_PROFILE")
            }
        }
        .tabViewStyle(.page)
    }
}

// MARK: - Lobby View (팀 선택 + Ready)
struct LobbyView: View {
    @StateObject private var wc = WatchConnectivityManager.shared
    @State private var selectedTeam: String? = nil

    var body: some View {
        let payload = wc.snapshot?.payload
        let isReady = payload?.profile?.isReady ?? false
        let currentTeam = payload?.team ?? "UNKNOWN"
        
        let effectiveTeam = selectedTeam ?? (currentTeam != "UNKNOWN" ? currentTeam : nil)
        
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                ConnectionPill(isConnected: wc.isReachable)
                
                HStack(spacing: 8) {
                    TeamSelectButton(
                        team: "POLICE",
                        label: "경찰",
                        isSelected: effectiveTeam == "POLICE",
                        isReady: isReady
                    ) {
                        selectedTeam = "POLICE"
                        wc.sendAction(action: "SELECT_TEAM", value: "POLICE")
                    }
                    
                    TeamSelectButton(
                        team: "THIEF",
                        label: "도둑",
                        isSelected: effectiveTeam == "THIEF",
                        isReady: isReady
                    ) {
                        selectedTeam = "THIEF"
                        wc.sendAction(action: "SELECT_TEAM", value: "THIEF")
                    }
                }
                
                ReadyButton(isReady: isReady) {
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
            }
            .padding()
        }
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

// MARK: - InGame Views
struct InGamePagerView: View {
    @StateObject private var wc = WatchConnectivityManager.shared

    // activeTab 기반 탭 선택 (폰 미러링) - 3탭 구조
    private var selectedIndex: Int {
        guard let activeTab = wc.snapshot?.payload.activeTab else { return 0 }
        switch activeTab {
        case "INGAME_RADAR": return 0
        case "INGAME_STATUS", "INGAME_CAPTURE", "INGAME_MAP": return 1  // 통합
        case "INGAME_RULES", "INGAME_SETTINGS": return 2  // 통합
        default: return 0
        }
    }

    var body: some View {
        TabView(selection: .constant(selectedIndex)) {
            InGameRadarView().tag(0)      // 그래픽 레이더
            InGameStatusView().tag(1)     // 통합 상태 뷰
            InGameRulesView().tag(2)      // 규칙
        }
        .tabViewStyle(.page)
    }
}

struct InGameRadarView: View {
    @StateObject private var wc = WatchConnectivityManager.shared

    var body: some View {
        let p = wc.snapshot?.payload
        let teamColor: Color = p?.team == "POLICE" ? .cyan : .red

        ZStack(alignment: .bottomTrailing) {
            VStack(spacing: 8) {
                // 상단 바: 연결 상태 + 심박수
                HStack {
                    ConnectionPill(isConnected: wc.isReachable)
                    Spacer()
                    if wc.currentHeartRate > 0 {
                        HeartRatePill(bpm: wc.currentHeartRate)
                    }
                }

                // 위험 경고 (도둑 전용)
                if (p?.nearby.enemyNear ?? false) && p?.team == "THIEF" {
                    DangerPill()
                }

                // 그래픽 레이더 (핵심)
                GraphicalRadarView(
                    allies: p?.nearby.allies ?? [],
                    heading: wc.currentHeading,
                    teamColor: teamColor
                )
                .frame(height: 120)

                // 하단: 남은 시간
                Text("남은 시간: \(p?.timeRemainSec ?? 0)s")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 8)
            .padding(.top, 4)
            .background(Color.black.opacity(0.92))
            .onTapGesture {
                wc.sendAction(action: "OPEN_TAB", value: "INGAME_RADAR")
            }

            // 스킬 버튼 오버레이 (우하단)
            if let skill = p?.my.skill, skill.type != "none" {
                SkillButtonOverlay(skill: skill)
            }
        }
    }
}

struct InGameStatusView: View {
    @StateObject private var wc = WatchConnectivityManager.shared

    var body: some View {
        let p = wc.snapshot?.payload
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                ConnectionPill(isConnected: wc.isReachable)
                Text("상태").font(.system(size: 16, weight: .bold))

                // 팀 카운트
                HStack {
                    StatItem(label: "경찰", value: "\(p?.counts.police ?? 0)", color: .cyan)
                    StatItem(label: "도둑", value: "\(p?.counts.thiefAlive ?? 0)", color: .red)
                }

                // 체포/해방
                if p?.team == "POLICE" {
                    StatItem(label: "체포", value: "\(p?.counts.thiefCaptured ?? 0)", color: .orange)
                } else {
                    StatItem(label: "해방", value: "\(p?.my.rescues ?? 0)", color: .green)
                }

                // 이동 거리
                StatItem(label: "이동", value: "\(p?.my.distanceM ?? 0)m", color: .purple)

                Spacer()
            }
            .padding()
        }
        .background(Color.black.opacity(0.92))
        .onTapGesture {
            wc.sendAction(action: "OPEN_TAB", value: "INGAME_STATUS")
        }
    }
}

struct InGameRulesView: View {
    @StateObject private var wc = WatchConnectivityManager.shared

    var body: some View {
        let r = wc.snapshot?.payload.rulesLite
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                ConnectionPill(isConnected: wc.isReachable)
                Text("규칙").font(.system(size: 16, weight: .bold))
                Text("접촉: \(r?.contactMode ?? "—")")
                Text("해방: \(r?.releaseScope ?? "—") \(r?.releaseOrder ?? "")")
                Text("감옥: \(r?.jailEnabled == true ? "ON" : "OFF")")
                Text("반경: \(r?.jailRadiusM ?? 0)m")
                Spacer()
            }
            .font(.system(size: 12, weight: .semibold))
            .foregroundColor(.secondary)
            .padding()
        }
        .background(Color.black.opacity(0.92))
        .onTapGesture {
            wc.sendAction(action: "OPEN_TAB", value: "INGAME_RULES")
        }
    }
}

// MARK: - PostGame View
struct PostGameView: View {
    @StateObject private var wc = WatchConnectivityManager.shared

    var body: some View {
        let p = wc.snapshot?.payload
        VStack(alignment: .leading, spacing: 10) {
            ConnectionPill(isConnected: wc.isReachable)
            Text("결과").font(.system(size: 16, weight: .bold))
            
            if p?.team == "POLICE" {
                Text("체포: \(p?.my.captures ?? 0)")
            } else {
                Text("해방: \(p?.my.rescues ?? 0)")
            }
            Text("이동: \(p?.my.distanceM ?? 0)m")
            Text("탈출: \(p?.my.escapeSec ?? 0)s")
            
            if let hrMax = p?.my.hrMax {
                Text("최대 심박: \(hrMax) bpm")
                    .foregroundColor(.red)
            }
            
            Spacer()
        }
        .font(.system(size: 12, weight: .semibold))
        .foregroundColor(.secondary)
        .padding()
        .background(Color.black.opacity(0.92))
    }
}

// MARK: - UI Components
struct ConnectionPill: View {
    let isConnected: Bool

    var body: some View {
        HStack {
            Circle()
                .fill(isConnected ? Color.green : Color.gray)
                .frame(width: 6, height: 6)
            Text(isConnected ? "연결됨" : "연결 끊김")
                .font(.system(size: 10, weight: .bold))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.black.opacity(0.6))
        .clipShape(Capsule())
    }
}

struct RankBadge: View {
    let label: String
    let rank: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 2) {
            Text(label)
                .font(.system(size: 9, weight: .medium))
                .foregroundColor(.secondary)
            Text(rank)
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(color)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.15))
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(color.opacity(0.5), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}

struct TeamSelectButton: View {
    let team: String
    let label: String
    let isSelected: Bool
    let isReady: Bool
    let action: () -> Void
    
    private var teamColor: Color {
        team == "POLICE" ? .cyan : .red
    }
    
    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 12, weight: .bold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(isSelected && isReady ? teamColor.opacity(0.6) : teamColor.opacity(0.15))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isSelected ? teamColor : teamColor.opacity(0.3), lineWidth: isSelected ? 2 : 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
    }
}

struct ReadyButton: View {
    let isReady: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(isReady ? "READY ✓" : "READY")
                .font(.system(size: 13, weight: .bold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(isReady ? Color.green.opacity(0.7) : Color.gray.opacity(0.3))
                .foregroundColor(isReady ? .white : .secondary)
                .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
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

struct HeartRatePill: View {
    let bpm: Int

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "heart.fill")
                .foregroundColor(.red)
                .font(.system(size: 10))
            Text("\(bpm)")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.white.opacity(0.1))
        .clipShape(Capsule())
    }
}

struct SkillButtonOverlay: View {
    let skill: SnapshotSkill

    var body: some View {
        Button(action: {
            WatchConnectivityManager.shared.sendAction(action: "USE_SKILL", value: nil)
        }) {
            ZStack {
                Circle().fill(Color.black.opacity(0.6)).frame(width: 50, height: 50)
                if !skill.ready {
                    Circle()
                        .trim(from: 0.0, to: CGFloat(1.0 - Double(skill.remain)/Double(max(1, skill.total))))
                        .stroke(Color.cyan, lineWidth: 3)
                        .rotationEffect(.degrees(-90))
                        .frame(width: 48, height: 48)
                } else {
                    Circle().stroke(Color.cyan, lineWidth: 3).frame(width: 50, height: 50)
                }

                Image(systemName: skill.sf)
                    .font(.system(size: 20))
                    .foregroundColor(skill.ready ? .white : .gray)

                if !skill.ready {
                    Text("\(skill.remain)")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
        .padding([.bottom, .trailing], 8)
        .disabled(!skill.ready)
    }
}

struct StatItem: View {
    let label: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 2) {
            Text(label)
                .font(.system(size: 9, weight: .medium))
                .foregroundColor(.secondary)
            Text(value)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(color)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(color.opacity(0.15))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(color.opacity(0.5), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
