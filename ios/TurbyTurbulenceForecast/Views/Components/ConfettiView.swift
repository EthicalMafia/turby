import SwiftUI

struct ConfettiView: View {
    @Binding var isActive: Bool
    @State private var particles: [ConfettiParticle] = []

    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                let now = timeline.date.timeIntervalSinceReferenceDate
                for particle in particles {
                    let elapsed = now - particle.startTime
                    guard elapsed < 2.5 else { continue }
                    let progress = elapsed / 2.5

                    let x = particle.startX * size.width + sin(elapsed * particle.wobble) * 30
                    let y = -20 + (size.height + 40) * progress * progress * 0.8
                    let opacity = max(0, 1.0 - progress * 0.6)
                    let rotation = Angle.degrees(elapsed * particle.spin)

                    context.opacity = opacity
                    context.translateBy(x: x, y: y)
                    context.rotate(by: rotation)

                    let rect = CGRect(x: -4, y: -6, width: 8, height: 12)
                    context.fill(
                        Path(roundedRect: rect, cornerRadius: 2),
                        with: .color(particle.color)
                    )

                    context.rotate(by: -rotation)
                    context.translateBy(x: -x, y: -y)
                }
            }
        }
        .allowsHitTesting(false)
        .onChange(of: isActive) { _, active in
            if active {
                spawnParticles()
                Task {
                    try? await Task.sleep(for: .seconds(3))
                    isActive = false
                    particles.removeAll()
                }
            }
        }
    }

    private func spawnParticles() {
        let colors: [Color] = [
            Color(red: 0.3, green: 0.78, blue: 0.55),
            Color(red: 0.42, green: 0.68, blue: 0.92),
            Color(red: 0.22, green: 0.45, blue: 0.78),
            .yellow, .orange, .pink, .mint
        ]
        let now = Date.now.timeIntervalSinceReferenceDate
        particles = (0..<50).map { _ in
            ConfettiParticle(
                startX: Double.random(in: 0.05...0.95),
                startTime: now + Double.random(in: 0...0.5),
                color: colors.randomElement()!,
                wobble: Double.random(in: 2...6),
                spin: Double.random(in: 60...360)
            )
        }
    }
}

struct ConfettiParticle {
    let startX: Double
    let startTime: TimeInterval
    let color: Color
    let wobble: Double
    let spin: Double
}
