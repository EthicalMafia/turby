import Foundation

nonisolated struct WindAtAltitude: Sendable {
    let latitude: Double
    let longitude: Double
    let windSpeed300hPa: Double
    let windSpeed500hPa: Double
    let windSpeed700hPa: Double
    let windSpeed850hPa: Double
    let windDirection300hPa: Double
    let windDirection500hPa: Double
    let temperature300hPa: Double
    let temperature250hPa: Double
}

nonisolated struct OpenMeteoResponse: Codable, Sendable {
    let hourly: OpenMeteoHourly?
}

nonisolated struct OpenMeteoHourly: Codable, Sendable {
    let time: [String]?
    let windspeed_300hPa: [Double?]?
    let windspeed_500hPa: [Double?]?
    let windspeed_700hPa: [Double?]?
    let windspeed_850hPa: [Double?]?
    let winddirection_300hPa: [Double?]?
    let winddirection_500hPa: [Double?]?
    let temperature_300hPa: [Double?]?
    let temperature_250hPa: [Double?]?

    enum CodingKeys: String, CodingKey {
        case time
        case windspeed_300hPa = "wind_speed_300hPa"
        case windspeed_500hPa = "wind_speed_500hPa"
        case windspeed_700hPa = "wind_speed_700hPa"
        case windspeed_850hPa = "wind_speed_850hPa"
        case winddirection_300hPa = "wind_direction_300hPa"
        case winddirection_500hPa = "wind_direction_500hPa"
        case temperature_300hPa = "temperature_300hPa"
        case temperature_250hPa = "temperature_250hPa"
    }
}

@MainActor
class OpenMeteoService {
    func fetchWindAlongRoute(points: [(lat: Double, lon: Double)], hourOffset: Int = 0) async -> [WindAtAltitude] {
        var results: [WindAtAltitude] = []

        let sampled = samplePoints(points, maxCount: 6)

        await withTaskGroup(of: (Int, WindAtAltitude?).self) { group in
            for (index, point) in sampled.enumerated() {
                group.addTask { [self] in
                    let wind = await self.fetchWindAt(lat: point.lat, lon: point.lon, hourOffset: hourOffset)
                    return (index, wind)
                }
            }
            var indexed: [(Int, WindAtAltitude)] = []
            for await (idx, wind) in group {
                if let w = wind { indexed.append((idx, w)) }
            }
            results = indexed.sorted { $0.0 < $1.0 }.map(\.1)
        }

        return results
    }

    private func fetchWindAt(lat: Double, lon: Double, hourOffset: Int = 0) async -> WindAtAltitude? {
        let variables = "wind_speed_300hPa,wind_speed_500hPa,wind_speed_700hPa,wind_speed_850hPa,wind_direction_300hPa,wind_direction_500hPa,temperature_300hPa,temperature_250hPa"
        let urlStr = "https://api.open-meteo.com/v1/forecast?latitude=\(lat)&longitude=\(lon)&hourly=\(variables)&wind_speed_unit=kn&forecast_days=1&timezone=UTC"

        guard let url = URL(string: urlStr) else { return nil }

        do {
            var request = URLRequest(url: url)
            request.timeoutInterval = 10
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else { return nil }

            let decoded = try JSONDecoder().decode(OpenMeteoResponse.self, from: data)
            guard let hourly = decoded.hourly else { return nil }

            let now = Date()
            let calendar = Calendar.current
            let currentHour = calendar.component(.hour, from: now)
            let targetHour = max(0, min(23, currentHour + hourOffset))
            let idx = min(targetHour, (hourly.time?.count ?? 1) - 1)

            return WindAtAltitude(
                latitude: lat,
                longitude: lon,
                windSpeed300hPa: hourly.windspeed_300hPa?[safe: idx] ?? 0,
                windSpeed500hPa: hourly.windspeed_500hPa?[safe: idx] ?? 0,
                windSpeed700hPa: hourly.windspeed_700hPa?[safe: idx] ?? 0,
                windSpeed850hPa: hourly.windspeed_850hPa?[safe: idx] ?? 0,
                windDirection300hPa: hourly.winddirection_300hPa?[safe: idx] ?? 0,
                windDirection500hPa: hourly.winddirection_500hPa?[safe: idx] ?? 0,
                temperature300hPa: hourly.temperature_300hPa?[safe: idx] ?? -44,
                temperature250hPa: hourly.temperature_250hPa?[safe: idx] ?? -52
            )
        } catch {
            return nil
        }
    }

    private func samplePoints(_ points: [(lat: Double, lon: Double)], maxCount: Int) -> [(lat: Double, lon: Double)] {
        guard points.count > maxCount else { return points }
        var sampled: [(lat: Double, lon: Double)] = []
        let step = Double(points.count - 1) / Double(maxCount - 1)
        for i in 0..<maxCount {
            let idx = Int(Double(i) * step)
            sampled.append(points[min(idx, points.count - 1)])
        }
        return sampled
    }
}

extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

extension Optional where Wrapped == Double {
    static func ?? (lhs: Double??, rhs: Double) -> Double {
        if let outer = lhs, let inner = outer {
            return inner
        }
        return rhs
    }
}
