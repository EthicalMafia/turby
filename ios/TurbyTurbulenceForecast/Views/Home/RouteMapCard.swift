import SwiftUI
import MapKit

struct RouteMapCard: View {
    let forecast: FlightForecast

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "map.fill")
                    .foregroundStyle(TurbyTurbulenceForecastTheme.accent)
                Text("Route Map")
                    .font(.headline)
                Spacer()
            }

            Map {
                Annotation(forecast.departureAirport.code, coordinate: forecast.departureAirport.coordinate) {
                    AirportPin(code: forecast.departureAirport.code, isDeparture: true)
                }
                Annotation(forecast.arrivalAirport.code, coordinate: forecast.arrivalAirport.coordinate) {
                    AirportPin(code: forecast.arrivalAirport.code, isDeparture: false)
                }
                ForEach(forecast.routePoints) { point in
                    Annotation("", coordinate: point.coordinate) {
                        Circle()
                            .fill(TurbyTurbulenceForecastTheme.turbulenceColor(for: point.turbulenceLevel))
                            .frame(width: 10, height: 10)
                            .shadow(color: TurbyTurbulenceForecastTheme.turbulenceColor(for: point.turbulenceLevel).opacity(0.5), radius: 4)
                    }
                }
                MapPolyline(coordinates: forecast.routePoints.map(\.coordinate))
                    .stroke(TurbyTurbulenceForecastTheme.accent.opacity(0.4), lineWidth: 2)
            }
            .mapStyle(.standard(pointsOfInterest: .excludingAll))
            .frame(height: 200)
            .clipShape(.rect(cornerRadius: 14))
            .allowsHitTesting(false)

            HStack(spacing: 16) {
                MapLegendItem(color: TurbyTurbulenceForecastTheme.turbulenceColor(for: .smooth), label: "Smooth")
                MapLegendItem(color: TurbyTurbulenceForecastTheme.turbulenceColor(for: .light), label: "Light")
                MapLegendItem(color: TurbyTurbulenceForecastTheme.turbulenceColor(for: .moderate), label: "Moderate")
                MapLegendItem(color: TurbyTurbulenceForecastTheme.turbulenceColor(for: .severe), label: "Severe")
            }
            .font(.caption2)
        }
        .padding(18)
        .glassCard()
    }
}

struct AirportPin: View {
    let code: String
    let isDeparture: Bool

    var body: some View {
        VStack(spacing: 2) {
            Image(systemName: isDeparture ? "airplane.departure" : "airplane.arrival")
                .font(.caption.weight(.bold))
                .foregroundStyle(.white)
                .padding(6)
                .background(Circle().fill(TurbyTurbulenceForecastTheme.accent))
            Text(code)
                .font(.caption2.weight(.bold))
                .foregroundStyle(.primary)
        }
    }
}

struct MapLegendItem: View {
    let color: Color
    let label: String

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(label)
                .foregroundStyle(.secondary)
        }
    }
}
