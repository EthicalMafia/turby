import SwiftUI

struct FlightAutocompleteField: View {
    let placeholder: String
    @Binding var text: String
    let suggestions: [FlightSuggestion]
    let isLoading: Bool
    let onSelect: (FlightSuggestion) -> Void
    @State private var showSuggestions: Bool = false
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                Image(systemName: "airplane")
                    .foregroundStyle(.secondary)
                    .frame(width: 20)
                TextField(placeholder, text: $text)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.characters)
                    .focused($isFocused)
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.7)
                        .frame(width: 20, height: 20)
                } else if !text.isEmpty {
                    Button {
                        text = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.tertiary)
                    }
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray6))
            )

            if showSuggestions && !suggestions.isEmpty {
                VStack(spacing: 0) {
                    if suggestions.count > 1 && suggestions.first?.dep.isEmpty == false {
                        HStack(spacing: 6) {
                            Image(systemName: "info.circle")
                                .font(.caption2)
                            Text("\(suggestions.count) flights found — select yours")
                                .font(.caption2)
                        }
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .frame(maxWidth: .infinity, alignment: .leading)

                        Divider().padding(.leading, 14)
                    }

                    ForEach(Array(suggestions.enumerated()), id: \.element.id) { index, suggestion in
                        Button {
                            text = suggestion.flight
                            showSuggestions = false
                            isFocused = false
                            onSelect(suggestion)
                        } label: {
                            if suggestion.dep.isEmpty {
                                HStack(spacing: 12) {
                                    Text(suggestion.flight)
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(.primary)
                                    Spacer()
                                    Text(suggestion.airline)
                                        .font(.caption2)
                                        .foregroundStyle(.tertiary)
                                        .lineLimit(1)
                                }
                                .padding(.horizontal, 14)
                                .padding(.vertical, 10)
                            } else {
                                SuggestionFlightRow(suggestion: suggestion)
                            }
                        }
                        if index < suggestions.count - 1 {
                            Divider().padding(.leading, 14)
                        }
                    }
                }
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemBackground))
                        .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
                )
                .padding(.top, 4)
            }
        }
        .onChange(of: text) { _, newValue in
            showSuggestions = !newValue.isEmpty && isFocused
        }
        .onChange(of: isFocused) { _, focused in
            showSuggestions = focused && !text.isEmpty
        }
    }
}

struct SuggestionFlightRow: View {
    let suggestion: FlightSuggestion

    private var isUpcoming: Bool {
        guard let timeStr = suggestion.depTimeLocal else { return false }
        guard let date = parseTimeString(timeStr) else { return false }
        return date > Date()
    }

    var body: some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Text(suggestion.dep)
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(.primary)
                    Image(systemName: "arrow.right")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                    Text(suggestion.arr)
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(.primary)

                    if isUpcoming {
                        Text("UPCOMING")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(Color.blue))
                    }
                }

                HStack(spacing: 12) {
                    if let depTime = formattedLocalTime(suggestion.depTimeLocal) {
                        HStack(spacing: 4) {
                            Image(systemName: "airplane.departure")
                                .font(.system(size: 9))
                                .foregroundStyle(.tertiary)
                            Text(depTime)
                                .font(.caption.weight(.semibold))
                                .monospacedDigit()
                        }
                        .foregroundStyle(.secondary)
                    }

                    if let arrTime = formattedLocalTime(suggestion.arrTimeLocal) {
                        HStack(spacing: 4) {
                            Image(systemName: "airplane.arrival")
                                .font(.system(size: 9))
                                .foregroundStyle(.tertiary)
                            Text(arrTime)
                                .font(.caption.weight(.semibold))
                                .monospacedDigit()
                        }
                        .foregroundStyle(.secondary)
                    }

                    if let status = suggestion.status {
                        Text(statusLabel(status))
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(statusColor(status))
                    }
                }
            }

            Spacer(minLength: 8)

            Image(systemName: "chevron.right")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.quaternary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }

    private func formattedLocalTime(_ timeStr: String?) -> String? {
        guard let timeStr else { return nil }
        guard let date = parseTimeString(timeStr) else { return nil }

        var airportTZ: TimeZone?
        if let offsetRange = timeStr.range(of: #"[+-]\d{2}:\d{2}$"#, options: .regularExpression) {
            let offsetStr = String(timeStr[offsetRange])
            let sign = offsetStr.hasPrefix("-") ? -1 : 1
            let parts = offsetStr.dropFirst().split(separator: ":")
            if parts.count == 2, let h = Int(parts[0]), let m = Int(parts[1]) {
                let seconds = sign * (h * 3600 + m * 60)
                airportTZ = TimeZone(secondsFromGMT: seconds)
            }
        }

        let df = DateFormatter()
        df.timeStyle = .short
        if let tz = airportTZ {
            df.timeZone = tz
        }
        return df.string(from: date)
    }

    private func parseTimeString(_ source: String) -> Date? {
        let isoFrac = ISO8601DateFormatter()
        isoFrac.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let d = isoFrac.date(from: source) { return d }

        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime]
        if let d = iso.date(from: source) { return d }

        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd HH:mmZ"
        return df.date(from: source)
    }

    private func statusLabel(_ status: String) -> String {
        let s = status.lowercased()
        if s.contains("scheduled") || s.contains("expected") { return "On Time" }
        if s.contains("active") || s.contains("en route") || s.contains("airborne") { return "In Flight" }
        if s.contains("landed") { return "Landed" }
        if s.contains("delayed") { return "Delayed" }
        if s.contains("cancelled") || s.contains("canceled") { return "Cancelled" }
        return "Scheduled"
    }

    private func statusColor(_ status: String) -> Color {
        let s = status.lowercased()
        if s.contains("cancelled") || s.contains("canceled") { return .red }
        if s.contains("delayed") { return .orange }
        if s.contains("active") || s.contains("en route") || s.contains("airborne") { return .blue }
        if s.contains("landed") { return .green }
        return .secondary
    }
}
