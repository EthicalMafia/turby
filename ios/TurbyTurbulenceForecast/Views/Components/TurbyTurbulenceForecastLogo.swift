import SwiftUI

struct TurbyTurbulenceForecastLogo: View {
    var style: LogoStyle = .standard

    enum LogoStyle {
        case standard
        case compact
        case onboarding
    }

    var body: some View {
        switch style {
        case .standard:
            standardLogo
        case .compact:
            compactLogo
        case .onboarding:
            onboardingLogo
        }
    }

    private var standardLogo: some View {
        HStack(spacing: 7) {
            logoMark(size: 28)
            Text("turby")
                .font(.system(size: 22, weight: .bold, design: .default))
                .tracking(-0.5)
                .foregroundStyle(
                    LinearGradient(
                        colors: [TurbyTurbulenceForecastTheme.accent, TurbyTurbulenceForecastTheme.accentLight],
                        startPoint: .leading, endPoint: .trailing
                    )
                )
        }
    }

    private var compactLogo: some View {
        HStack(spacing: 5) {
            logoMark(size: 22)
            Text("turby")
                .font(.system(size: 17, weight: .bold, design: .default))
                .tracking(-0.3)
                .foregroundStyle(
                    LinearGradient(
                        colors: [TurbyTurbulenceForecastTheme.accent, TurbyTurbulenceForecastTheme.accentLight],
                        startPoint: .leading, endPoint: .trailing
                    )
                )
        }
    }

    private var onboardingLogo: some View {
        HStack(spacing: 10) {
            logoMark(size: 40)
                .shadow(color: .white.opacity(0.3), radius: 8)
            Text("turby")
                .font(.system(size: 34, weight: .bold, design: .default))
                .tracking(-0.8)
                .foregroundStyle(.white)
        }
    }

    private func logoMark(size: CGFloat) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.25)
                .fill(
                    LinearGradient(
                        colors: [TurbyTurbulenceForecastTheme.accentLight, TurbyTurbulenceForecastTheme.accent],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: size, height: size)

            Image(systemName: "airplane")
                .font(.system(size: size * 0.48, weight: .semibold))
                .foregroundStyle(.white)
                .rotationEffect(.degrees(-30))
                .offset(x: size * 0.02, y: -size * 0.02)
        }
    }
}
