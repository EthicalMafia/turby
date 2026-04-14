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

    func fetchDepartures(airportIata: String, dateComponents: (year: Int, month: Int, day: Int)) async throws -> [ADBFlightResponse] {
        let fromStr = String(format: "%04d-%02d-%02dT00:00", dateComponents.year, dateComponents.month, dateComponents.day)
        let toStr = String(format: "%04d-%02d-%02dT23:59", dateComponents.year, dateComponents.month, dateComponents.day)

        let timeWindows: [(String, String)] = [
            (String(format: "%04d-%02d-%02dT00:00", dateComponents.year, dateComponents.month, dateComponents.day),
             String(format: "%04d-%02d-%02dT11:59", dateComponents.year, dateComponents.month, dateComponents.day)),
            (String(format: "%04d-%02d-%02dT12:00", dateComponents.year, dateComponents.month, dateComponents.day),
             String(format: "%04d-%02d-%02dT23:59", dateComponents.year, dateComponents.month, dateComponents.day))
        ]

        var allDepartures: [ADBFlightResponse] = []
        var lastError: ADBError?

        for (index, (windowFrom, windowTo)) in timeWindows.enumerated() {
            if index > 0 {
                try? await Task.sleep(for: .milliseconds(300))
            }

            let path = "/flights/airports/iata/\(airportIata)/\(windowFrom)/\(windowTo)?direction=Departure&withLeg=true&withCancelled=false&withCodeshared=true&withPrivate=false&withLocation=true"

            guard let url = URL(string: baseURL + path) else {
                throw ADBError.invalidURL
            }

            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.setValue(apiKey, forHTTPHeaderField: "x-rapidapi-key")
            request.setValue(host, forHTTPHeaderField: "x-rapidapi-host")
            request.timeoutInterval = 20

            do {
                let (data, response) = try await URLSession.shared.data(for: request)

                guard let httpResponse = response as? HTTPURLResponse else {
                    lastError = .invalidResponse
                    continue
                }

                switch httpResponse.statusCode {
                case 200:
                    let decoder = JSONDecoder()
                    let fids = try decoder.decode(ADBFIDSResponse.self, from: data)
                    allDepartures.append(contentsOf: fids.departures ?? [])
                case 204, 404:
                    break
                case 401, 403:
                    throw ADBError.unauthorized
                case 429:
                    lastError = .rateLimited
                    continue
                default:
                    if let raw = String(data: data, encoding: .utf8) {
                        print("[AeroDataBox] Error \(httpResponse.statusCode): \(raw.prefix(300))")
                    }
                    lastError = .serverError(httpResponse.statusCode)
                    continue
                }
            } catch let error as ADBError {
                throw error
            } catch {
                lastError = .invalidResponse
                continue
            }
        }

        if allDepartures.isEmpty, let lastError {
            throw lastError
        }

        return allDepartures
    }

    func fetchFlightStatus(flightNumber: String, date: Date? = nil) async throws -> [ADBFlightResponse] {
        let cleaned = flightNumber.uppercased().trimmingCharacters(in: .whitespaces).replacingOccurrences(of: " ", with: "")

        var path = "/flights/number/\(cleaned)"
        if let date {
            var cal = Calendar.current
            cal.timeZone = .current
            let y = cal.component(.year, from: date)
            let m = cal.component(.month, from: date)
            let d = cal.component(.day, from: date)
            path += "/\(String(format: "%04d-%02d-%02d", y, m, d))"
        }
        path += "?withLocation=true"

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
            do {
                let decoder = JSONDecoder()
                let flights = try decoder.decode([ADBFlightResponse].self, from: data)
                return flights
            } catch {
                print("[AeroDataBox] Flight decode error: \(error)")
                if let raw = String(data: data, encoding: .utf8) {
                    print("[AeroDataBox] Raw response: \(raw.prefix(500))")
                }
                throw ADBError.decodingError
            }
        case 204:
            return []
        case 401, 403:
            throw ADBError.unauthorized
        case 404:
            return []
        case 429:
            throw ADBError.rateLimited
        default:
            if let raw = String(data: data, encoding: .utf8) {
                print("[AeroDataBox] Error \(httpResponse.statusCode): \(raw.prefix(300))")
            }
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
    case decodingError

    var errorDescription: String? {
        switch self {
        case .invalidURL: "Invalid request."
        case .invalidResponse: "Could not connect to flight data service."
        case .unauthorized: "Flight data API key is invalid. Check Settings."
        case .rateLimited: "Too many requests. Please wait a moment."
        case .serverError(let code): "Flight data service error (\(code))."
        case .noFlightFound: "No flight found with that number."
        case .decodingError: "Unexpected response from flight data service."
        }
    }
}
