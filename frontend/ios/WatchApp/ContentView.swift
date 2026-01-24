import SwiftUI

struct ContentView: View {
    @StateObject private var wc = WatchConnectivityManager.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("레이더").font(.headline)

            if let p = wc.latest {
                Text("Heading: \(Int(p.headingDeg))°").font(.caption)
                Text("Ping: \(p.pings.count)").font(.caption)

                if let prog = p.captureProgress01 {
                    ProgressView(value: prog)
                        .progressViewStyle(.linear)
                }

                List(p.pings.prefix(6)) { ping in
                    HStack {
                        Text(ping.kind).font(.caption2)
                        Spacer()
                        Text("\(Int(ping.bearingDeg))°").font(.caption2)
                        Text("\(Int(ping.distanceM))m").font(.caption2)
                    }
                }
            } else {
                Text("수신 대기 중…").font(.caption)
                ProgressView()
            }
        }
        .onAppear { wc.setup() }
    }
}
