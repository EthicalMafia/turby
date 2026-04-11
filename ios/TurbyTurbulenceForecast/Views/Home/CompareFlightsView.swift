import SwiftUI

struct CompareFlightsView: View {
    let currentForecast: FlightForecast
    let flightService: FlightService
    @State private var alternativeFlights: [AlternativeFlight] = []
    @State private var isLoading = true
    @State private var appeared = false

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Image(systemName: "arrow.left.arrow.right")
                    .foregroundStyle(TurbyTurbulenceForecastTheme.accent)
                Text("Alternative Times")
                    .font(.headline)
                Spacer()
                Text("Real weather data")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Text("Wind conditions at different departure times today")
                .font(.caption)
                .foregroundStyle(.secondary)

            if isLoading {
                HStack {
                    Spacer()
                    VStack(spacing: 8) {
                        ProgressView()
                        Text("Checking conditions...")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                .padding(.vertical, 16)
            } else if alternativeFlights.isEmpty {
                HStack {
                    Image(systemName: "info.circle")
                        .foregroundStyle(.secondary)
                    Text("Could not load alternative times")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 12)
            } else {
                ForEach(Array(alternativeFlights.enumerated()), id: \.element.id) { index, flight in
                    AlternativeFlightRow(
                        flight: flight,
                        isBest: flight.id == alternativeFlights.min(by: { $0.score < $1.score })?.id,
                        isCurrent: flight.hourOffset == 0
                    )
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 10)
                    .animation(.spring(response: 0.4).delay(Double(index) * 0.08), value: appeared)
                }
            }
        }
        .padding(18)
        .glassCard()
        .task {
            await fetchAlternatives()
            withAnimation(.easeIn(duration: 0.5).delay(0.1)) { appeared = true }
        }
    }

    private func fetchAlternatives() async {
        let offsets = [-3, -1, 0, 1, 3]

        await withTaskGroup(of: AlternativeFlight?.self) { group in
            for offset in offsets {
                group.addTask {
                    if offset == 0 {
                        return AlternativeFlight(
                            id: "current",
                            timeLabel: "Current time",
                            score: currentForecast.overallScore,
                            level: currentForecast.overallLevel,
                            hourOffset: 0
                        )
                    }
                    let score = await flightService.fetchTimeShiftedScore(
                        forecast: currentForecast,
                        hourOffset: offset
                    )
                    let label = offset > 0 ? "\(offset)h later" : "\(abs(offset))h earlier"
                    return AlternativeFlight(
                        id: "offset_\(offset)",
                        timeLabel: label,
                        score: score,
                        level: turbulenceForScore(score),
                        hourOffset: offset
                    )
                }
            }
            var results: [AlternativeFlight] = []
            for await flight in group {
                if let f = flight { results.append(f) }
            }
            alternativeFlights = results.sorted { $0.hourOffset < $1.hourOffset }
        }
        isLoading = false
    }

    private func turbulenceForScore(_ score: Int) -> TurbulenceLevel {
        switch score {
        case 0...2: .smooth
        case 3...4: .light
        case 5...7: .moderate
        default: .severe
        }
    }
}

struct AlternativeFlight: Identifiable {
    let id: String
    let timeLabel: String
    let score: Int
    let level: TurbulenceLevel
    let hourOffset: Int
}

struct AlternativeFlightRow: View {
    let flight: AlternativeFlight
    let isBest: Bool
    let isCurrent: Bool
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(flight.timeLabel)
                        .font(.subheadline.weight(.medium))
                    if isCurrent {
                        Text("YOUR FLIGHT")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(TurbyTurbulenceForecastTheme.accent))
                    } else if isBest {
                        Text("SMOOTHEST")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(TurbyTurbulenceForecastTheme.turbulenceColor(for: .smooth)))
                    }
                }
                Text(flight.level.label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text("\(flight.score)")
                .font(.title3.weight(.bold))
                .foregroundStyle(TurbyTurbulenceForecastTheme.scoreColor(for: flight.score))
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isCurrent ? TurbyTurbulenceForecastTheme.accent.opacity(0.06) : (isBest ? TurbyTurbulenceForecastTheme.turbulenceColor(for: .smooth).opacity(0.06) : Color(.systemGray6).opacity(colorScheme == .dark ? 0.3 : 1)))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(isCurrent ? TurbyTurbulenceForecastTheme.accent.opacity(0.3) : (isBest ? TurbyTurbulenceForecastTheme.turbulenceColor(for: .smooth).opacity(0.3) : .clear), lineWidth: 1)
                )
        )
    }
}
