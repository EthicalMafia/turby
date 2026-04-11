import SwiftUI

struct CalmModeView: View {
    @Environment(\.colorScheme) private var colorScheme
    @State private var breathPhase: BreathPhase = .inhale
    @State private var breathScale: CGFloat = 0.5
    @State private var isBreathing: Bool = false
    @State private var cycleCount: Int = 0
    @State private var breathTask: Task<Void, Never>?
    @State private var hapticPhase: BreathPhase = .inhale
    @State private var countdown: Int = 4

    var body: some View {
        NavigationStack {
            ZStack {
                TurbyTurbulenceForecastTheme.calmBackground(for: colorScheme)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        breathingSection
                        reassuranceCards
                        turbulenceFacts
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 40)
                }
                .scrollIndicators(.hidden)
            }
            .navigationTitle("Calm Mode")
            .navigationBarTitleDisplayMode(.inline)
        }
        .sensoryFeedback(.impact(weight: .medium, intensity: 0.6), trigger: hapticPhase)
    }

    private var phaseColor: Color {
        switch breathPhase {
        case .inhale: TurbyTurbulenceForecastTheme.accent
        case .hold: Color(red: 0.45, green: 0.38, blue: 0.82)
        case .exhale: Color(red: 0.25, green: 0.65, blue: 0.72)
        }
    }

    private var breathingSection: some View {
        VStack(spacing: 20) {
            Text(isBreathing ? "Follow the rhythm" : "Take a moment to breathe")
                .font(.title3.weight(.semibold))
                .animation(.easeInOut, value: isBreathing)

            ZStack {
                ForEach(0..<4, id: \.self) { i in
                    Circle()
                        .fill(phaseColor.opacity(0.04 + Double(i) * 0.03))
                        .frame(
                            width: 140 + CGFloat(i) * 40,
                            height: 140 + CGFloat(i) * 40
                        )
                        .scaleEffect(breathScale - CGFloat(i) * 0.04)
                }

                Circle()
                    .strokeBorder(phaseColor.opacity(0.5), lineWidth: 3)
                    .frame(width: 140, height: 140)
                    .scaleEffect(breathScale)
                    .shadow(color: phaseColor.opacity(0.4), radius: isBreathing ? 20 : 0)

                Circle()
                    .fill(
                        RadialGradient(
                            colors: [phaseColor.opacity(0.25), phaseColor.opacity(0.08)],
                            center: .center,
                            startRadius: 0,
                            endRadius: 70
                        )
                    )
                    .frame(width: 140, height: 140)
                    .scaleEffect(breathScale)

                VStack(spacing: 6) {
                    Text(breathPhase.instruction)
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(phaseColor)
                        .contentTransition(.interpolate)

                    if isBreathing {
                        Text("\(countdown)")
                            .font(.system(.title, design: .rounded, weight: .bold))
                            .foregroundStyle(phaseColor.opacity(0.7))
                            .contentTransition(.numericText(countsDown: true))
                            .transition(.opacity)
                    }
                }
            }
            .frame(height: 300)
            .animation(.easeInOut(duration: breathPhase.duration), value: breathScale)
            .animation(.easeInOut(duration: 0.6), value: breathPhase)

            Button {
                if isBreathing {
                    stopBreathing()
                } else {
                    startBreathing()
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: isBreathing ? "stop.fill" : "play.fill")
                        .font(.caption)
                    Text(isBreathing ? "Stop" : "Begin Breathing")
                }
                .font(.headline)
                .foregroundStyle(.white)
                .padding(.horizontal, 32)
                .padding(.vertical, 14)
                .background(
                    Capsule()
                        .fill(phaseColor)
                        .shadow(color: phaseColor.opacity(0.3), radius: 8, y: 4)
                )
            }

            if cycleCount > 0 {
                HStack(spacing: 6) {
                    Image(systemName: "leaf.fill")
                        .font(.caption)
                        .foregroundStyle(TurbyTurbulenceForecastTheme.turbulenceColor(for: .smooth))
                    Text("\(cycleCount) cycle\(cycleCount == 1 ? "" : "s") completed")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .transition(.opacity.combined(with: .scale(scale: 0.8)))
            }
        }
        .padding(24)
        .glassCard()
        .animation(.easeInOut(duration: 0.3), value: cycleCount)
    }

    private var reassuranceCards: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "heart.fill")
                    .foregroundStyle(.pink)
                Text("Reassurance")
                    .font(.headline)
                Spacer()
            }

            ForEach(reassuranceMessages, id: \.self) { message in
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(TurbyTurbulenceForecastTheme.turbulenceColor(for: .smooth))
                        .font(.subheadline)
                    Text(message)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemGray6).opacity(colorScheme == .dark ? 0.3 : 1))
                )
            }
        }
        .padding(18)
        .glassCard()
    }

    private var turbulenceFacts: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundStyle(.yellow)
                Text("Did You Know?")
                    .font(.headline)
                Spacer()
            }

            ForEach(calmingFacts, id: \.self) { fact in
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "star.fill")
                        .foregroundStyle(.yellow.opacity(0.6))
                        .font(.caption)
                    Text(fact)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemGray6).opacity(colorScheme == .dark ? 0.3 : 1))
                )
            }
        }
        .padding(18)
        .glassCard()
    }

    private var reassuranceMessages: [String] {
        [
            "Turbulence has never caused a modern commercial aircraft to crash.",
            "Pilots train hundreds of hours specifically for turbulence scenarios.",
            "Aircraft wings can flex over 90 degrees before any concern — they're incredibly strong.",
            "Air traffic control actively monitors and reroutes flights away from severe weather.",
            "You are statistically safer in a plane than driving to the airport."
        ]
    }

    private var calmingFacts: [String] {
        [
            "Over 100,000 flights take off and land safely worldwide every single day.",
            "Modern aircraft are tested to withstand 1.5x the most extreme forces ever recorded in flight.",
            "Turbulence feels worse than it actually is — the plane barely moves compared to what you feel.",
            "Sitting over the wings is the smoothest spot. It's closest to the plane's center of gravity."
        ]
    }

    private func startBreathing() {
        isBreathing = true
        breathTask?.cancel()
        breathTask = Task {
            await runBreathLoop()
        }
    }

    private func stopBreathing() {
        isBreathing = false
        breathTask?.cancel()
        breathTask = nil
        withAnimation(.easeInOut(duration: 0.6)) {
            breathScale = 0.5
            breathPhase = .inhale
            countdown = 4
        }
    }

    private func runBreathLoop() async {
        while !Task.isCancelled && isBreathing {
            breathPhase = .inhale
            hapticPhase = .inhale
            withAnimation(.easeInOut(duration: 4.0)) {
                breathScale = 1.0
            }
            guard await countdownPhase(seconds: 4) else { return }

            breathPhase = .hold
            hapticPhase = .hold
            guard await countdownPhase(seconds: 4) else { return }

            breathPhase = .exhale
            hapticPhase = .exhale
            withAnimation(.easeInOut(duration: 4.0)) {
                breathScale = 0.5
            }
            guard await countdownPhase(seconds: 4) else { return }

            cycleCount += 1
        }
    }

    private func countdownPhase(seconds: Int) async -> Bool {
        for i in (1...seconds).reversed() {
            withAnimation(.snappy) {
                countdown = i
            }
            guard await sleepFor(seconds: 1.0) else { return false }
        }
        return true
    }

    private func sleepFor(seconds: Double) async -> Bool {
        do {
            try await Task.sleep(for: .milliseconds(Int(seconds * 1000)))
            return true
        } catch {
            return false
        }
    }
}

enum BreathPhase: Hashable {
    case inhale, hold, exhale

    var instruction: String {
        switch self {
        case .inhale: "Breathe In"
        case .hold: "Hold"
        case .exhale: "Breathe Out"
        }
    }

    var duration: Double {
        switch self {
        case .inhale: 4.0
        case .hold: 4.0
        case .exhale: 4.0
        }
    }
}
