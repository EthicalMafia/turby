import SwiftUI

struct OnboardingHookPage: View {
    @State private var planeOffset: CGFloat = -200
    @State private var textOpacity: Double = 0
    @State private var planeHover: Bool = false
    @State private var ripplePhase: Bool = false
    @State private var planeGlow: Bool = false

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            VStack(spacing: 28) {
                ZStack {
                    ForEach(0..<3, id: \.self) { i in
                        Circle()
                            .stroke(.white.opacity(0.08), lineWidth: 1.5)
                            .fill(.white.opacity(ripplePhase ? 0.03 : 0.06))
                            .frame(
                                width: CGFloat(180 + i * 50) + (ripplePhase ? CGFloat(i * 8) : 0),
                                height: CGFloat(180 + i * 50) + (ripplePhase ? CGFloat(i * 8) : 0)
                            )
                            .opacity(ripplePhase ? (0.4 + Double(i) * 0.15) : (0.7 + Double(i) * 0.1))
                            .animation(
                                .easeInOut(duration: 2.5 + Double(i) * 0.4)
                                .repeatForever(autoreverses: true)
                                .delay(Double(i) * 0.3),
                                value: ripplePhase
                            )
                    }

                    Image(systemName: "airplane")
                        .font(.system(size: 72, weight: .light))
                        .foregroundStyle(.white)
                        .rotationEffect(.degrees(planeHover ? -12 : -18))
                        .offset(x: planeOffset, y: planeHover ? -6 : 6)
                        .shadow(color: .white.opacity(planeGlow ? 0.5 : 0.2), radius: planeGlow ? 30 : 15)
                        .animation(
                            .easeInOut(duration: 3.0).repeatForever(autoreverses: true),
                            value: planeHover
                        )
                        .animation(
                            .easeInOut(duration: 2.0).repeatForever(autoreverses: true),
                            value: planeGlow
                        )
                }

                TurbyTurbulenceForecastLogo(style: .onboarding)
            }

            VStack(spacing: 16) {
                Text("Will your flight\nbe bumpy?")
                    .font(.system(.title, design: .default, weight: .bold))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)

                Text("Get your personalized turbulence forecast\nin seconds — before you even board.")
                    .font(.body)
                    .foregroundStyle(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .opacity(textOpacity)

            Spacer()
            Spacer()
        }
        .padding(.horizontal, 24)
        .onAppear {
            withAnimation(.spring(response: 1.0, dampingFraction: 0.7).delay(0.2)) {
                planeOffset = 0
            }
            withAnimation(.easeIn(duration: 0.6).delay(0.5)) {
                textOpacity = 1
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                planeHover = true
                planeGlow = true
                ripplePhase = true
            }
        }
    }
}
