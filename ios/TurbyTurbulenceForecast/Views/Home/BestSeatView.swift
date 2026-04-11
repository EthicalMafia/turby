import SwiftUI

struct BestSeatView: View {
    let forecast: FlightForecast

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Image(systemName: "chair.lounge.fill")
                    .foregroundStyle(TurbyTurbulenceForecastTheme.accent)
                Text("Best Seat for a Smooth Ride")
                    .font(.headline)
                Spacer()
                premiumBadge
            }

            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(
                            LinearGradient(
                                colors: [TurbyTurbulenceForecastTheme.accent.opacity(0.15), TurbyTurbulenceForecastTheme.accent.opacity(0.05)],
                                startPoint: .top, endPoint: .bottom
                            )
                        )
                        .frame(width: 72, height: 72)
                    Image(systemName: forecast.bestSeat.icon)
                        .font(.system(size: 28))
                        .foregroundStyle(TurbyTurbulenceForecastTheme.accent)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text(forecast.bestSeat.zone)
                        .font(.title3.weight(.bold))
                    Text(forecast.bestSeat.row)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text(forecast.bestSeat.reason)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            seatDiagram
        }
        .padding(18)
        .glassCard()
    }

    private var premiumBadge: some View {
        Text("PRO")
            .font(.caption2.weight(.bold))
            .foregroundStyle(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [TurbyTurbulenceForecastTheme.accent, TurbyTurbulenceForecastTheme.accentLight],
                            startPoint: .leading, endPoint: .trailing
                        )
                    )
            )
    }

    private var seatDiagram: some View {
        VStack(spacing: 4) {
            HStack(spacing: 2) {
                ForEach(0..<30, id: \.self) { row in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(seatColor(for: row))
                        .frame(width: 8, height: 16)
                }
            }
            HStack {
                Text("Front")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("Wings")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(TurbyTurbulenceForecastTheme.accent)
                Spacer()
                Text("Rear")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(.systemGray6).opacity(0.5))
        )
    }

    private func seatColor(for row: Int) -> Color {
        if row >= 12 && row <= 20 {
            return TurbyTurbulenceForecastTheme.turbulenceColor(for: .smooth).opacity(0.7)
        } else if row >= 8 && row <= 24 {
            return TurbyTurbulenceForecastTheme.turbulenceColor(for: .light).opacity(0.5)
        } else {
            return TurbyTurbulenceForecastTheme.turbulenceColor(for: .moderate).opacity(0.3)
        }
    }
}
