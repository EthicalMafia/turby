import Foundation

nonisolated struct ADBFlightResponse: Codable, Sendable {
    let departure: ADBFlightEndpoint?
    let arrival: ADBFlightEndpoint?
    let status: String?
    let number: String?
    let airline: ADBFlightAirline?
    let aircraft: ADBFlightAircraft?
}

nonisolated struct ADBFlightEndpoint: Codable, Sendable {
    let airport: ADBFlightAirport?
    let scheduledTime: ADBFlightTime?
    let revisedTime: ADBFlightTime?
    let actualTime: ADBFlightTime?
    let terminal: String?
    let gate: String?
    let quality: [String]?
}

nonisolated struct ADBFlightAirport: Codable, Sendable {
    let iata: String?
    let icao: String?
    let name: String?
    let municipalityName: String?
    let location: ADBLocation?
}

nonisolated struct ADBLocation: Codable, Sendable {
    let lat: Double?
    let lon: Double?
}

nonisolated struct ADBFlightTime: Codable, Sendable {
    let utc: String?
    let local: String?
}

nonisolated struct ADBFlightAirline: Codable, Sendable {
    let name: String?
    let iata: String?
}

nonisolated struct ADBFlightAircraft: Codable, Sendable {
    let model: String?
    let reg: String?
}

nonisolated struct ADBFIDSResponse: Codable, Sendable {
    let departures: [ADBFlightResponse]?
    let arrivals: [ADBFlightResponse]?
}

@MainActor
class AeroDataBoxService {
    private let apiKey: String
    private let baseURL = "https://aerodatabox.p.rapidapi.com"
    private let host = "aerodatabox.p.rapidapi.com"

    init(apiKey: String) {
        self.apiKey = apiKey
    }

    func fetchDepartures(airportIata: String, from: Date, to: Date) async throws -> [ADBFlightResponse] {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm"
        formatter.timeZone = TimeZone.current

        let maxInterval: TimeInterval = 11 * 3600 + 59 * 60
        var allDepartures: [ADBFlightResponse] = []
        var windowStart = from

        while windowStart < to {
            let windowEnd = min(windowStart.addingTimeInterval(maxInterval), to)
            let fromStr = formatter.string(from: windowStart)
            let toStr = formatter.string(from: windowEnd)

            let path = "/flights/airports/iata/\(airportIata)/\(fromStr)/\(toStr)?direction=Departure&withLeg=true&withCancelled=false&withCodeshared=false&withPrivate=false&withLocation=true"

            guard let url = URL(string: baseURL + path) else {
                throw ADBError.invalidURL
            }

            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.setValue(apiKey, forHTTPHeaderField: "x-rapidapi-key")
            request.setValue(host, forHTTPHeaderField: "x-rapidapi-host")
            request.timeoutInterval = 20

            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw ADBError.invalidResponse
            }

            switch httpResponse.statusCode {
            case 200:
                let decoder = JSONDecoder()
                let fids = try decoder.decode(ADBFIDSResponse.self, from: data)
                allDepartures.append(contentsOf: fids.departures ?? [])
            case 204:
                break
            case 401, 403:
                throw ADBError.unauthorized
            case 404:
                break
            case 429:
                throw ADBError.rateLimited
            default:
                throw ADBError.serverError(httpResponse.statusCode)
            }

            windowStart = windowEnd
        }

        return allDepartures
    }

    func fetchFlightStatus(flightNumber: String, date: Date? = nil) async throws -> [ADBFlightResponse] {
        let cleaned = flightNumber.uppercased().trimmingCharacters(in: .whitespaces).replacingOccurrences(of: " ", with: "")

        var path = "/flights/number/\(cleaned)"
        if let date {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            formatter.timeZone = TimeZone(identifier: "UTC")
            path += "/\(formatter.string(from: date))"
        }

        guard let url = URL(string: baseURL + path) else {
            throw ADBError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(apiKey, forHTTPHeaderField: "x-rapidapi-key")
        request.setValue(host, forHTTPHeaderField: "x-rapidapi-host")
        request.timeoutInterval = 15

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw ADBError.invalidResponse
        }

        switch httpResponse.statusCode {
        case 200:
            let decoder = JSONDecoder()
            let flights = try decoder.decode([ADBFlightResponse].self, from: data)
            return flights
        case 204:
            return []
        case 401, 403:
            throw ADBError.unauthorized
        case 404:
            return []
        case 429:
            throw ADBError.rateLimited
        default:
            throw ADBError.serverError(httpResponse.statusCode)
        }
    }
}

nonisolated enum ADBError: Error, Sendable, LocalizedError {
    case invalidURL
    case invalidResponse
    case unauthorized
    case rateLimited
    case serverError(Int)
    case noFlightFound

    var errorDescription: String? {
        switch self {
        case .invalidURL: "Invalid request."
        case .invalidResponse: "Could not connect to flight data service."
        case .unauthorized: "Flight data API key is invalid. Check Settings."
        case .rateLimited: "Too many requests. Please wait a moment."
        case .serverError(let code): "Flight data service error (\(code))."
        case .noFlightFound: "No flight found with that number."
        }
    }
}
