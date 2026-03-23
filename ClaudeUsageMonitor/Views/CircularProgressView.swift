import SwiftUI

struct CircularProgressView: View {
    let progress: Double       // 0.0 – 1.0
    let messagesUsed: Int
    let messagesLimit: Int
    var lineWidth: CGFloat = 14

    private var displayPercentage: Int { Int(progress * 100) }

    // The gradient always spans 0 → 1 so the visible segment colour
    // naturally transitions green → yellow → red as progress climbs.
    // startAngle: 0° (not -90°) because the Circle also has .rotationEffect(-90°)
    // which would shift the gradient by another 90° — the two cancel out correctly.
    private let trackGradient = AngularGradient(
        stops: [
            .init(color: .green,  location: 0.0),
            .init(color: .yellow, location: 0.5),
            .init(color: .orange, location: 0.7),
            .init(color: .red,    location: 0.85),
            .init(color: .red,    location: 1.0),
        ],
        center: .center,
        startAngle: .degrees(0),
        endAngle:   .degrees(360)
    )

    var body: some View {
        ZStack {
            // Background track
            Circle()
                .stroke(Color.primary.opacity(0.08), lineWidth: lineWidth)

            // Coloured progress arc
            Circle()
                .trim(from: 0, to: max(0.005, progress))
                .stroke(
                    trackGradient,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.spring(response: 0.7, dampingFraction: 0.8), value: progress)

            // Central labels
            VStack(spacing: 4) {
                Text("\(displayPercentage)%")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundStyle(percentageColor)
                    .contentTransition(.numericText())
                    .animation(.easeInOut(duration: 0.4), value: displayPercentage)

                if messagesLimit > 0 {
                    Text("\(messagesUsed) of \(messagesLimit)")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                } else {
                    Text("No data")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(.tertiary)
                }
            }
        }
    }

    private var percentageColor: Color {
        switch progress {
        case 0.8...: return .red
        case 0.5...: return .orange
        default:     return .green
        }
    }
}

