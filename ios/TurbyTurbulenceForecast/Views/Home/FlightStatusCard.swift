import SwiftUI

struct FlightStatusCard: View {
    let forecast: FlightForecast
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    statusBadge
                    if let aircraft = forecast.aircraftModel {
                        Text(aircraft)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Departs")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                        Text(forecast.departureTime, style: .time)
                            .font(.subheadline.weight(.semibold))
                            .monospacedDigit()
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Arrives")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                        Text(forecast.arrivalTime, style: .time)
                            .font(.subheadline.weight(.semibold))
                            .monospacedDigit()
                    }

                    if let gateDisplay = gateText {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Gate")
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                            Text(gateDisplay)
                                .font(.subheadline.weight(.semibold))
                        }
                    }

                    if let terminal = forecast.departureTerminal {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Terminal")
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                            Text(terminal)
                                .font(.subheadline.weight(.semibold))
                        }
                    }
                }
            }

            Spacer()

            Image(systemName: resolvedStatus.icon)
                .font(.title2)
                .foregroundStyle(resolvedStatus.color)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(colorScheme == .dark
                      ? Color.white.opacity(0.06)
                      : Color(.systemBackground).opacity(0.9))
                .shadow(color: TurbyTurbulenceForecastTheme.cardShadow(for: colorScheme), radius: 16, y: 6)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .strokeBorder(resolvedStatus.color.opacity(0.2), lineWidth: 1)
        )
    }

    private var statusBadge: some View {
        Text(resolvedStatus.label)
            .font(.caption2.weight(.bold))
            .foregroundStyle(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(Capsule().fill(resolvedStatus.color))
    }

    private var gateText: String? {
        if let gate = forecast.departureGate, !gate.isEmpty {
            return gate
        }
        return nil
    }

    private var resolvedStatus: FlightStatus {
        guard let raw = forecast.flightStatus?.lowercased() else { return .unknown }
        if raw.contains("scheduled") || raw.contains("expected") { return .onTime }
        if raw.contains("active") || raw.contains("en route") || raw.contains("airborne") { return .enRoute }
        if raw.contains("landed") { return .landed }
        if raw.contains("delayed") { return .delayed }
        if raw.contains("cancelled") || raw.contains("canceled") { return .cancelled }
        if raw.contains("diverted") { return .diverted }
        if raw.contains("boarding") { return .boarding }
        return .onTime
    }
}

nonisolated enum FlightStatus: String, Sendable {
    case onTime
    case delayed
    case boarding
    case enRoute
    case landed
    case cancelled
    case diverted
    case unknown

    var label: String {
        switch self {
        case .onTime: "On Time"
        case .delayed: "Delayed"
        case .boarding: "Boarding"
        case .enRoute: "In Flight"
        case .landed: "Landed"
        case .cancelled: "Cancelled"
        case .diverted: "Diverted"
        case .unknown: "Status N/A"
        }
    }

    var color: Color {
        switch self {
        case .onTime: Color(red: 0.20, green: 0.78, blue: 0.55)
        case .delayed: Color(red: 0.95, green: 0.50, blue: 0.20)
        case .boarding: TurbyTurbulenceForecastTheme.accent
        case .enRoute: TurbyTurbulenceForecastTheme.accent
        case .landed: Color(red: 0.20, green: 0.78, blue: 0.55)
        case .cancelled: Color(red: 0.92, green: 0.28, blue: 0.28)
        case .diverted: Color(red: 0.95, green: 0.50, blue: 0.20)
        case .unknown: Color(.secondaryLabel)
        }
    }

    var icon: String {
        switch self {
        case .onTime: "checkmark.circle.fill"
        case .delayed: "clock.badge.exclamationmark.fill"
        case .boarding: "door.left.hand.open"
        case .enRoute: "airplane"
        case .landed: "arrow.down.circle.fill"
        case .cancelled: "xmark.circle.fill"
        case .diverted: "arrow.triangle.branch"
        case .unknown: "questionmark.circle"
        }
    }
}
