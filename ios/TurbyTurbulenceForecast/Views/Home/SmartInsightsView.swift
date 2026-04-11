import SwiftUI

struct WhatThisMeansView: View {
    let forecast: FlightForecast
    let profile: PassengerProfile

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundStyle(.yellow)
                Text("What This Means For You")
                    .font(.headline)
                Spacer()
            }

            VStack(spacing: 10) {
                SensationRow(
                    phase: "Takeoff",
                    level: forecast.takeoffCondition,
                    icon: "airplane.departure"
                )
                SensationRow(
                    phase: "Cruise",
                    level: forecast.cruiseCondition,
                    icon: "airplane"
                )
                SensationRow(
                    phase: "Landing",
                    level: forecast.landingCondition,
                    icon: "airplane.arrival"
                )
            }

            if profile == .nervous {
                HStack(spacing: 10) {
                    Image(systemName: "heart.fill")
                        .foregroundStyle(.pink)
                    Text(forecast.overallLevel.nervousReassurance)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.pink.opacity(0.06))
                )
            }
        }
        .padding(18)
        .glassCard()
    }
}

struct SensationRow: View {
    let phase: String
    let level: TurbulenceLevel
    let icon: String
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(TurbyTurbulenceForecastTheme.turbulenceColor(for: level).opacity(0.12))
                    .frame(width: 28, height: 28)
                Image(systemName: icon)
                    .font(.caption2)
                    .foregroundStyle(TurbyTurbulenceForecastTheme.turbulenceColor(for: level))
            }

            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(phase)
                        .font(.subheadline.weight(.medium))
                    Spacer()
                    Text(level.label)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(TurbyTurbulenceForecastTheme.turbulenceColor(for: level))
                }
                Text(level.sensation)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6).opacity(colorScheme == .dark ? 0.3 : 1))
        )
    }
}

struct PilotInsightView: View {
    let forecast: FlightForecast

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Image(systemName: "person.badge.shield.checkmark.fill")
                    .foregroundStyle(.orange)
                Text("Pilot Insight")
                    .font(.headline)
                Spacer()
            }

            VStack(spacing: 10) {
                PilotInsightRow(
                    title: "During takeoff",
                    detail: forecast.takeoffCondition.pilotAction
                )
                PilotInsightRow(
                    title: "At cruise altitude",
                    detail: forecast.cruiseCondition.pilotAction
                )
                PilotInsightRow(
                    title: "On approach",
                    detail: forecast.landingCondition.pilotAction
                )
            }

            HStack(spacing: 8) {
                Image(systemName: "checkmark.seal.fill")
                    .foregroundStyle(TurbyTurbulenceForecastTheme.turbulenceColor(for: .smooth))
                Text("Pilots receive real-time weather updates and will always try to find smoother air.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(TurbyTurbulenceForecastTheme.turbulenceColor(for: .smooth).opacity(0.06))
            )
        }
        .padding(18)
        .glassCard()
    }
}

struct PilotInsightRow: View {
    let title: String
    let detail: String
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.subheadline.weight(.medium))
            Text(detail)
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6).opacity(colorScheme == .dark ? 0.3 : 1))
        )
    }
}
