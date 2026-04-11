import SwiftUI

struct RegionalTurbulenceView: View {
    let insights: [TurbulenceRegionInsight]
    let departureCode: String
    let arrivalCode: String
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        if !insights.isEmpty {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Image(systemName: "location.fill.viewfinder")
                        .foregroundStyle(TurbyTurbulenceForecastTheme.accent)
                    Text("Turbulence Hotspots")
                        .font(.headline)
                    Spacer()
                }

                VStack(spacing: 0) {
                    ForEach(Array(insights.enumerated()), id: \.element.id) { index, insight in
                        RegionalInsightRow(
                            insight: insight,
                            departureCode: departureCode,
                            arrivalCode: arrivalCode,
                            isLast: index == insights.count - 1
                        )
                    }
                }

                if insights.allSatisfy({ $0.turbulenceLevel == .light }) {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(TurbyTurbulenceForecastTheme.turbulenceColor(for: .smooth))
                        Text("Only minor bumps expected — nothing to worry about.")
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
            }
            .padding(18)
            .glassCard()
        }
    }
}

struct RegionalInsightRow: View {
    let insight: TurbulenceRegionInsight
    let departureCode: String
    let arrivalCode: String
    let isLast: Bool
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(spacing: 0) {
                ZStack {
                    Circle()
                        .fill(TurbyTurbulenceForecastTheme.turbulenceColor(for: insight.turbulenceLevel).opacity(0.15))
                        .frame(width: 32, height: 32)
                    Image(systemName: insight.turbulenceLevel.icon)
                        .font(.caption)
                        .foregroundStyle(TurbyTurbulenceForecastTheme.turbulenceColor(for: insight.turbulenceLevel))
                }

                if !isLast {
                    Rectangle()
                        .fill(Color(.systemGray4))
                        .frame(width: 2, height: 20)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(insightDescription)
                    .font(.subheadline.weight(.medium))
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 8) {
                    Text(insight.turbulenceLevel.label)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(TurbyTurbulenceForecastTheme.turbulenceColor(for: insight.turbulenceLevel))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(
                            Capsule()
                                .fill(TurbyTurbulenceForecastTheme.turbulenceColor(for: insight.turbulenceLevel).opacity(0.12))
                        )

                    Text(progressLabel)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
            .padding(.bottom, isLast ? 0 : 10)
        }
    }

    private var insightDescription: String {
        switch insight.turbulenceLevel {
        case .smooth:
            return "Smooth conditions over \(insight.regionName)"
        case .light:
            return "Light bumps possible over \(insight.regionName)"
        case .moderate:
            return "Expect turbulence over \(insight.regionName)"
        case .severe:
            return "Significant turbulence expected over \(insight.regionName)"
        }
    }

    private var progressLabel: String {
        let pct = Int(insight.flightProgressPercent * 100)
        if pct < 25 { return "Early in flight" }
        if pct < 50 { return "First half of flight" }
        if pct < 75 { return "Second half of flight" }
        return "Late in flight"
    }
}
