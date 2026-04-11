import SwiftUI

struct ShareCardView: View {
    let forecast: FlightForecast

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(forecast.flightNumber)
                            .font(.title2.weight(.bold))
                            .foregroundStyle(.white)
                        HStack(spacing: 6) {
                            Text(forecast.departureAirport.code)
                            Image(systemName: "arrow.right")
                                .font(.caption)
                            Text(forecast.arrivalAirport.code)
                        }
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.white.opacity(0.85))
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("\(forecast.overallScore)")
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                        Text("/ 10")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.7))
                    }
                }

                HStack(spacing: 0) {
                    SharePhaseIndicator(phase: "Takeoff", level: forecast.takeoffCondition)
                    SharePhaseIndicator(phase: "Cruise", level: forecast.cruiseCondition)
                    SharePhaseIndicator(phase: "Landing", level: forecast.landingCondition)
                }

                Text(forecast.overallLevel.simpleLabel)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.white.opacity(0.9))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(.white.opacity(0.15))
                    )
            }
            .padding(20)
            .background(
                LinearGradient(
                    colors: [Color(red: 0.30, green: 0.55, blue: 0.90), Color(red: 0.18, green: 0.38, blue: 0.72)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )

            HStack(spacing: 6) {
                Image(systemName: "airplane")
                    .font(.caption.weight(.bold))
                Text("turby")
                    .font(.subheadline.weight(.bold))
                    .tracking(-0.3)
                Spacer()
                Text(forecast.departureTime, style: .date)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color(.systemBackground))
        }
        .clipShape(.rect(cornerRadius: 16))
        .shadow(color: .black.opacity(0.15), radius: 12, y: 6)
    }
}

struct SharePhaseIndicator: View {
    let phase: String
    let level: TurbulenceLevel

    var body: some View {
        VStack(spacing: 4) {
            Circle()
                .fill(TurbyTurbulenceForecastTheme.turbulenceColor(for: level))
                .frame(width: 10, height: 10)
            Text(phase)
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.7))
            Text(level.label)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity)
    }
}

struct FlightShareButton: View {
    let forecast: FlightForecast

    var body: some View {
        ShareLink(
            item: shareText,
            subject: Text("Flight Forecast"),
            message: Text(shareText)
        ) {
            HStack(spacing: 8) {
                Image(systemName: "square.and.arrow.up")
                Text("Share Forecast")
            }
            .font(.subheadline.weight(.medium))
            .foregroundStyle(Color(red: 0.22, green: 0.45, blue: 0.78))
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                Capsule()
                    .fill(Color(red: 0.22, green: 0.45, blue: 0.78).opacity(0.1))
            )
        }
    }

    private var shareText: String {
        "My flight \(forecast.flightNumber) (\(forecast.departureAirport.code) -> \(forecast.arrivalAirport.code)) has a turbulence score of \(forecast.overallScore)/10 - \(forecast.overallLevel.simpleLabel). Check yours on Turby!"
    }
}
