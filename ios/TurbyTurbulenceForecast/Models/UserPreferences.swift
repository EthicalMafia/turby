import Foundation

nonisolated struct SavedAirport: Codable, Sendable {
    let iata: String
    let name: String
    let city: String
    let country: String
}

nonisolated struct SavedAirline: Codable, Sendable {
    let iata: String
    let name: String
    let country: String
}
