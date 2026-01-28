import SwiftUI

/// Main graphical radar view showing allies as dots on a circular radar
struct GraphicalRadarView: View {
    let allies: [AllyBlip]
    let heading: Double       // current compass heading
    let teamColor: Color      // cyan for police, red for thief

    private let maxRadius: Double = 30.0  // 30m range

    var body: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            let center = CGPoint(x: size/2, y: size/2)
            let radius = size/2 - 8  // padding

            ZStack {
                // Background: concentric circles + crosshairs + north indicator
                RadarBackground(radius: radius)

                // Render ally dots
                ForEach(allies) { ally in
                    AllyDot(
                        ally: ally,
                        center: center,
                        radius: radius,
                        maxRadius: maxRadius,
                        color: teamColor
                    )
                }

                // Center: my position
                Circle()
                    .fill(Color.white)
                    .frame(width: 8, height: 8)
                    .position(center)
            }
        }
        .aspectRatio(1, contentMode: .fit)
    }
}

/// Radar background with concentric circles (10m, 20m, 30m), crosshairs, and north indicator
struct RadarBackground: View {
    let radius: CGFloat

    var body: some View {
        Canvas { context, size in
            let center = CGPoint(x: size.width/2, y: size.height/2)

            // Draw concentric circles: 10m, 20m, 30m
            for i in 1...3 {
                let r = radius * CGFloat(i) / 3.0
                let circle = Path(ellipseIn: CGRect(
                    x: center.x - r,
                    y: center.y - r,
                    width: r * 2,
                    height: r * 2
                ))
                context.stroke(circle, with: .color(.gray.opacity(0.3)), lineWidth: 1)
            }

            // Draw crosshairs
            var crossH = Path()
            crossH.move(to: CGPoint(x: 0, y: center.y))
            crossH.addLine(to: CGPoint(x: size.width, y: center.y))

            var crossV = Path()
            crossV.move(to: CGPoint(x: center.x, y: 0))
            crossV.addLine(to: CGPoint(x: center.x, y: size.height))

            context.stroke(crossH, with: .color(.gray.opacity(0.2)), lineWidth: 1)
            context.stroke(crossV, with: .color(.gray.opacity(0.2)), lineWidth: 1)

            // North indicator (top, 12 o'clock position)
            let northIndicator = Path { p in
                p.move(to: CGPoint(x: center.x, y: 4))
                p.addLine(to: CGPoint(x: center.x - 4, y: 12))
                p.addLine(to: CGPoint(x: center.x + 4, y: 12))
                p.closeSubpath()
            }
            context.fill(northIndicator, with: .color(.cyan.opacity(0.6)))
        }
    }
}

/// Individual ally dot rendered on the radar
struct AllyDot: View {
    let ally: AllyBlip
    let center: CGPoint
    let radius: CGFloat
    let maxRadius: Double
    let color: Color

    var body: some View {
        let position = calculatePosition()

        Circle()
            .fill(color)
            .frame(width: 10, height: 10)
            .shadow(color: color, radius: 4)
            .position(position)
    }

    private func calculatePosition() -> CGPoint {
        // Convert bearing to screen coordinates
        // b: -180 ~ 180 (0 = forward, positive = right)
        // Adjust by -90 so 12 o'clock is 0 degrees
        let theta = (ally.b - 90) * (.pi / 180)

        // Normalize distance (0 ~ 1)
        let normalizedDist = min(ally.d / maxRadius, 1.0)
        let r = radius * CGFloat(normalizedDist)

        let x = center.x + r * CGFloat(cos(theta))
        let y = center.y + r * CGFloat(sin(theta))

        return CGPoint(x: x, y: y)
    }
}
