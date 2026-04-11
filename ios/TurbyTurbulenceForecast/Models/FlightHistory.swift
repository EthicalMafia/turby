import Foundation

nonisolated struct FlightHistoryEntry: Codable, Sendable, Identifiable {
    let id: String
    let flightNumber: String
    let departureCode: String
    let arrivalCode: String
    let date: Date
    let overallScore: Int
    let overallLevel: String
    let forecast: FlightForecast

    init(forecast: FlightForecast) {
        self.id = forecast.id
        self.flightNumber = forecast.flightNumber
        self.departureCode = forecast.departureAirport.code
        self.arrivalCode = forecast.arrivalAirport.code
        self.date = forecast.departureTime
        self.overallScore = forecast.overallScore
        self.overallLevel = forecast.overallLevel.rawValue
        self.forecast = forecast
    }

    var turbulenceLevel: TurbulenceLevel {
        TurbulenceLevel(rawValue: overallLevel) ?? .smooth
    }
}
