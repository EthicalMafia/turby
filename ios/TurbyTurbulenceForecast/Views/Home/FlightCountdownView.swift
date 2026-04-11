import SwiftUI

struct FlightCountdownView: View {
    let departureTime: Date
    var flightStatus: String?
    @Environment(\.colorScheme) private var colorScheme
    @State private var timeRemaining: TimeInterval = 0
    @State private var timer: Timer?

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(TurbyTurbulenceForecastTheme.accent.opacity(0.12))
                    .frame(width: 44, height: 44)
                Image(systemName: "clock.fill")
                    .font(.body)
                    .foregroundStyle(TurbyTurbulenceForecastTheme.accent)
            }

            VStack(alignment: .leading, spacing: 2) {
                if isCancelled {
                    Text("Flight cancelled")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.red)
                } else if timeRemaining > 0 {
                    Text("Departure in")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(countdownString)
                        .font(.title3.weight(.bold))
                        .monospacedDigit()
                } else {
                    Text("Flight departed")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("Confidence")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                HStack(spacing: 4) {
                    Image(systemName: confidenceIcon)
                        .font(.caption)
                        .foregroundStyle(confidenceColor)
                    Text(confidenceLabel)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(confidenceColor)
                }
            }
        }
        .padding(16)
        .glassCard()
        .onAppear { startTimer() }
        .onDisappear { timer?.invalidate() }
    }

    private var countdownString: String {
        let hours = Int(timeRemaining) / 3600
        let minutes = (Int(timeRemaining) % 3600) / 60
        let seconds = Int(timeRemaining) % 60

        if hours > 24 {
            let days = hours / 24
            return "\(days)d \(hours % 24)h"
        }
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }

    private var isCancelled: Bool {
        guard let status = flightStatus?.lowercased() else { return false }
        return status.contains("cancelled") || status.contains("canceled")
    }

    private var confidenceLabel: String {
        if isCancelled { return "N/A" }
        if timeRemaining < 3600 { return "Very High" }
        if timeRemaining < 14400 { return "High" }
        if timeRemaining < 43200 { return "Good" }
        return "Moderate"
    }

    private var confidenceColor: Color {
        if isCancelled { return .secondary }
        if timeRemaining < 3600 { return TurbyTurbulenceForecastTheme.turbulenceColor(for: .smooth) }
        if timeRemaining < 14400 { return TurbyTurbulenceForecastTheme.turbulenceColor(for: .smooth) }
        if timeRemaining < 43200 { return TurbyTurbulenceForecastTheme.turbulenceColor(for: .light) }
        return TurbyTurbulenceForecastTheme.turbulenceColor(for: .moderate)
    }

    private var confidenceIcon: String {
        if timeRemaining < 14400 { return "checkmark.circle.fill" }
        return "circle.dotted"
    }

    private func startTimer() {
        updateTimeRemaining()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            Task { @MainActor in
                updateTimeRemaining()
            }
        }
    }

    private func updateTimeRemaining() {
        timeRemaining = max(0, departureTime.timeIntervalSinceNow)
    }
}
