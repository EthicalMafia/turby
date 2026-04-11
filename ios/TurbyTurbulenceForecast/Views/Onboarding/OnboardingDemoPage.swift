import SwiftUI

struct OnboardingDemoPage: View {
    @State private var appeared = false
    @State private var scoreAnimated = false

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            VStack(spacing: 8) {
                Text("See exactly what you'll get")
                    .font(.system(.title2, design: .default, weight: .bold))
                    .foregroundStyle(.white)
                Text("Real data. Plain English. Zero jargon.")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.8))
            }

            VStack(spacing: 16) {
                HStack(spacing: 0) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("AA 1234")
                            .font(.headline)
                        Text("JFK \u{2192} LAX")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Text("5h 20m")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Divider()

                HStack(spacing: 20) {
                    DemoConditionPill(label: "Takeoff", level: .smooth)
                    DemoConditionPill(label: "Cruise", level: .light)
                    DemoConditionPill(label: "Landing", level: .smooth)
                }

                Divider()

                VStack(spacing: 8) {
                    HStack {
                        Text("Turbulence Score")
                            .font(.subheadline.weight(.medium))
                        Spacer()
                        Text("2/10")
                            .font(.title3.weight(.bold))
                            .foregroundStyle(TurbyTurbulenceForecastTheme.scoreColor(for: 2))
                    }

                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Color(.systemGray5))
                            Capsule()
                                .fill(TurbyTurbulenceForecastTheme.scoreColor(for: 2))
                                .frame(width: scoreAnimated ? geo.size.width * 0.2 : 0)
                        }
                    }
                    .frame(height: 8)

                    Text("Smooth sailing - sit back and relax")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Divider()

                HStack(spacing: 10) {
                    Image(systemName: "lightbulb.fill")
                        .foregroundStyle(.yellow)
                        .font(.caption)
                    Text("\"Like sitting on your couch - you won't feel a thing.\"")
                        .font(.caption)
                        .italic()
                        .foregroundStyle(.secondary)
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.1), radius: 20, y: 10)
            )
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 30)
            .scaleEffect(appeared ? 1 : 0.92)

            Text("Plus: seat tips, breathing exercises,\npilot insights & more")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.8))
                .multilineTextAlignment(.center)

            Spacer()
            Spacer()
        }
        .padding(.horizontal, 24)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.2)) {
                appeared = true
            }
            withAnimation(.easeOut(duration: 0.8).delay(0.7)) {
                scoreAnimated = true
            }
        }
    }
}

struct DemoConditionPill: View {
    let label: String
    let level: TurbulenceLevel

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: level.icon)
                .font(.title3)
                .foregroundStyle(TurbyTurbulenceForecastTheme.turbulenceColor(for: level))
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(level.label)
                .font(.caption.weight(.semibold))
                .foregroundStyle(TurbyTurbulenceForecastTheme.turbulenceColor(for: level))
        }
        .frame(maxWidth: .infinity)
    }
}
