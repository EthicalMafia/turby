import SwiftUI

struct FlightPickerSheet: View {
    let flights: [ADBFlightResponse]
    let departureCode: String
    let searchDate: Date
    let onSelect: (ADBFlightResponse) -> Void
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    private var upcomingCount: Int {
        flights.filter { isUpcoming($0) }.count
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    VStack(spacing: 6) {
                        Text("\(flights.count) flights found")
                            .font(.subheadline.weight(.semibold))
                        Text("\(departureCode) · \(formattedDate)")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(.secondary)
                        if upcomingCount > 0 {
                            Text("\(upcomingCount) upcoming · Select your flight below")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        } else {
                            Text("Select your specific flight below")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .multilineTextAlignment(.center)
                    .padding(.top, 8)

                    ForEach(Array(flights.enumerated()), id: \.offset) { index, flight in
                        Button {
                            onSelect(flight)
                        } label: {
                            FlightOptionRow(flight: flight, isUpcoming: isUpcoming(flight), fallbackDepartureCode: departureCode)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 32)
            }
            .navigationTitle("Select Flight")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private func isUpcoming(_ flight: ADBFlightResponse) -> Bool {
        guard let timeStr = flight.departure?.scheduledTime?.utc ?? flight.departure?.scheduledTime?.local else { return false }
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let d = formatter.date(from: timeStr), d > Date() { return true }
        formatter.formatOptions = [.withInternetDateTime]
        if let d = formatter.date(from: timeStr), d > Date() { return true }
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd HH:mmZ"
        if let d = df.date(from: timeStr), d > Date() { return true }
        return false
    }

    private var formattedDate: String {
        let df = DateFormatter()
        df.dateStyle = .medium
        return df.string(from: searchDate)
    }
}

struct FlightOptionRow: View {
    let flight: ADBFlightResponse
    let isUpcoming: Bool
    var fallbackDepartureCode: String = "???"
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    if let number = flight.number {
                        Text(number)
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(.primary)
                    }

                    if let airlineName = flight.airline?.name {
                        Text(airlineName)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }

                    Spacer()

                    if isUpcoming {
                        Text("UPCOMING")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Capsule().fill(TurbyTurbulenceForecastTheme.accent))
                    }

                    if let status = flight.status {
                        Text(statusLabel(status))
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(statusColor(status))
                    }
                }

                HStack(spacing: 8) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(flight.departure?.airport?.iata ?? fallbackDepartureCode)
                            .font(.headline.weight(.bold))
                        Text(flight.departure?.airport?.municipalityName ?? "")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }

                    Image(systemName: "arrow.right")
                        .font(.caption)
                        .foregroundStyle(.tertiary)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(flight.arrival?.airport?.iata ?? "???")
                            .font(.headline.weight(.bold))
                        Text(flight.arrival?.airport?.municipalityName ?? "")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }

                HStack(spacing: 16) {
                    if let depTime = displayTime(flight.departure?.scheduledTime) {
                        VStack(alignment: .leading, spacing: 1) {
                            Text("Departs")
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                            Text(depTime)
                                .font(.caption.weight(.semibold))
                                .monospacedDigit()
                        }
                    }

                    if let arrTime = displayTime(flight.arrival?.scheduledTime) {
                        VStack(alignment: .leading, spacing: 1) {
                            Text("Arrives")
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                            Text(arrTime)
                                .font(.caption.weight(.semibold))
                                .monospacedDigit()
                        }
                    }

                    if let terminal = flight.departure?.terminal {
                        VStack(alignment: .leading, spacing: 1) {
                            Text("Terminal")
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                            Text(terminal)
                                .font(.caption.weight(.semibold))
                        }
                    }

                    if let aircraft = flight.aircraft?.model {
                        VStack(alignment: .leading, spacing: 1) {
                            Text("Aircraft")
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                            Text(aircraft)
                                .font(.caption.weight(.semibold))
                                .lineLimit(1)
                        }
                    }
                }
            }

            Spacer(minLength: 4)

            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .foregroundStyle(.primary)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(colorScheme == .dark
                      ? Color.white.opacity(isUpcoming ? 0.08 : 0.04)
                      : Color(.systemBackground).opacity(isUpcoming ? 1 : 0.8))
                .shadow(color: isUpcoming ? TurbyTurbulenceForecastTheme.accent.opacity(0.15) : .clear, radius: 8, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(
                    isUpcoming ? TurbyTurbulenceForecastTheme.accent.opacity(0.3) : Color.clear,
                    lineWidth: 1
                )
        )
    }

    private func displayTime(_ time: ADBFlightTime?) -> String? {
        let localStr = time?.local
        let utcStr = time?.utc
        let source = localStr ?? utcStr
        guard let source else { return nil }

        var date: Date?
        var airportTZ: TimeZone?

        let isoFrac = ISO8601DateFormatter()
        isoFrac.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        date = isoFrac.date(from: source)

        if date == nil {
            let iso = ISO8601DateFormatter()
            iso.formatOptions = [.withInternetDateTime]
            date = iso.date(from: source)
        }

        if date == nil {
            let df = DateFormatter()
            df.dateFormat = "yyyy-MM-dd HH:mmZ"
            date = df.date(from: source)
        }

        if localStr != nil, let offsetRange = localStr!.range(of: #"[+-]\d{2}:\d{2}$"#, options: .regularExpression) {
            let offsetStr = String(localStr![offsetRange])
            let sign = offsetStr.hasPrefix("-") ? -1 : 1
            let parts = offsetStr.dropFirst().split(separator: ":")
            if parts.count == 2, let h = Int(parts[0]), let m = Int(parts[1]) {
                let seconds = sign * (h * 3600 + m * 60)
                airportTZ = TimeZone(secondsFromGMT: seconds)
            }
        }

        guard let d = date else { return nil }
        let df = DateFormatter()
        df.timeStyle = .short
        if let tz = airportTZ {
            df.timeZone = tz
        }
        return df.string(from: d)
    }

    private func statusLabel(_ status: String) -> String {
        let s = status.lowercased()
        if s.contains("scheduled") || s.contains("expected") { return "On Time" }
        if s.contains("active") || s.contains("en route") || s.contains("airborne") { return "In Flight" }
        if s.contains("landed") { return "Landed" }
        if s.contains("delayed") { return "Delayed" }
        if s.contains("cancelled") || s.contains("canceled") { return "Cancelled" }
        if s.contains("diverted") { return "Diverted" }
        if s.contains("boarding") { return "Boarding" }
        return "Scheduled"
    }

    private func statusColor(_ status: String) -> Color {
        let s = status.lowercased()
        if s.contains("cancelled") || s.contains("canceled") { return .red }
        if s.contains("delayed") { return .orange }
        if s.contains("active") || s.contains("en route") || s.contains("airborne") { return TurbyTurbulenceForecastTheme.accent }
        if s.contains("landed") { return TurbyTurbulenceForecastTheme.turbulenceColor(for: .smooth) }
        return .secondary
    }
}
