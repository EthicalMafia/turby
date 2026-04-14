import SwiftUI
import StoreKit
import RevenueCat
import WidgetKit

@Observable
@MainActor
class AppViewModel {
    var hasCompletedOnboarding: Bool = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
    var isPilotMode: Bool = false

    var appearanceMode: AppearanceMode = {
        if let raw = UserDefaults.standard.string(forKey: "appearanceMode"),
           let mode = AppearanceMode(rawValue: raw) {
            return mode
        }
        return .system
    }() {
        didSet {
            UserDefaults.standard.set(appearanceMode.rawValue, forKey: "appearanceMode")
        }
    }
    var showPaywall: Bool = false

    var showExitIntent: Bool = false
    var isOnboardingPaywall: Bool = false
    var currentForecast: FlightForecast?
    var searchQuery = FlightSearchQuery()
    var selectedTab: Int = 0
    var shouldRequestReview: Bool = false
    var showConfetti: Bool = false
    var showFlightPicker: Bool = false
    var availableFlights: [ADBFlightResponse] = []
    var preselectedFlight: ADBFlightResponse?

    var didRateInOnboarding: Bool = UserDefaults.standard.bool(forKey: "didRateInOnboarding") {
        didSet { UserDefaults.standard.set(didRateInOnboarding, forKey: "didRateInOnboarding") }
    }

    var forecastCount: Int = UserDefaults.standard.integer(forKey: "forecastCount") {
        didSet { UserDefaults.standard.set(forecastCount, forKey: "forecastCount") }
    }

    var forecastTimestamp: Date?

    var homeAirport: AirportInfo? = {
        if let data = UserDefaults.standard.data(forKey: "homeAirport"),
           let saved = try? JSONDecoder().decode(SavedAirport.self, from: data) {
            return AirportInfo(iata: saved.iata, name: saved.name, city: saved.city, country: saved.country)
        }
        return nil
    }() {
        didSet {
            if let airport = homeAirport {
                let saved = SavedAirport(iata: airport.iata, name: airport.name, city: airport.city, country: airport.country)
                if let data = try? JSONEncoder().encode(saved) {
                    UserDefaults.standard.set(data, forKey: "homeAirport")
                }
            } else {
                UserDefaults.standard.removeObject(forKey: "homeAirport")
            }
        }
    }

    var favoriteAirline: AirlineInfo? = {
        if let data = UserDefaults.standard.data(forKey: "favoriteAirline"),
           let saved = try? JSONDecoder().decode(SavedAirline.self, from: data) {
            return AirlineInfo(iata: saved.iata, name: saved.name, country: saved.country)
        }
        return nil
    }() {
        didSet {
            if let airline = favoriteAirline {
                let saved = SavedAirline(iata: airline.iata, name: airline.name, country: airline.country)
                if let data = try? JSONEncoder().encode(saved) {
                    UserDefaults.standard.set(data, forKey: "favoriteAirline")
                }
            } else {
                UserDefaults.standard.removeObject(forKey: "favoriteAirline")
            }
        }
    }

    var firstName: String = UserDefaults.standard.string(forKey: "userFirstName") ?? "" {
        didSet {
            UserDefaults.standard.set(firstName, forKey: "userFirstName")
        }
    }

    var passengerProfile: PassengerProfile = {
        if let raw = UserDefaults.standard.string(forKey: "passengerProfile"),
           let profile = PassengerProfile(rawValue: raw) {
            return profile
        }
        return .nervous
    }() {
        didSet {
            UserDefaults.standard.set(passengerProfile.rawValue, forKey: "passengerProfile")
        }
    }

    let flightService = FlightService()
    let subscriptionService = SubscriptionService()
    let notificationService = NotificationService()
    let historyService = FlightHistoryService()

    func completeOnboarding() {
        hasCompletedOnboarding = true
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
    }

    func searchFlight() async {
        currentForecast = nil
        forecastTimestamp = nil
        flightService.errorMessage = nil
        flightService.isLoading = true

        if !searchQuery.searchByFlightNumber && searchQuery.departureAirport.isEmpty, let home = homeAirport {
            searchQuery.departureAirport = home.iata
        }

        if searchQuery.searchByFlightNumber {
            if let validationError = flightService.validateFlightNumber(searchQuery.flightNumber) {
                flightService.isLoading = false
                flightService.errorMessage = validationError
                return
            }

            if let selected = preselectedFlight {
                preselectedFlight = nil
                await selectFlight(selected)
                return
            }

            let flights = await flightService.fetchAllFlightsFromAPI(
                flightNumber: searchQuery.flightNumber,
                date: searchQuery.date
            )

            if flights.isEmpty {
                flightService.isLoading = false
                flightService.errorMessage = "No flights found for that number on \(formattedSearchDate). Check the flight number and date."
                return
            }

            let sorted = sortFlightsByUpcoming(flights)

            if sorted.count == 1 {
                await selectFlight(sorted[0])
            } else {
                flightService.isLoading = false
                availableFlights = sorted
                showFlightPicker = true
            }
        } else {
            let depCode = searchQuery.departureAirport.uppercased().trimmingCharacters(in: .whitespaces)
            let arrCode = searchQuery.arrivalAirport.uppercased().trimmingCharacters(in: .whitespaces)

            guard !depCode.isEmpty, !arrCode.isEmpty else {
                flightService.isLoading = false
                flightService.errorMessage = "Please enter both departure and arrival airports."
                return
            }

            let flights = await flightService.fetchFlightsByRoute(
                departureIata: depCode,
                arrivalIata: arrCode,
                date: searchQuery.date
            )

            if flights.isEmpty {
                flightService.isLoading = false
                if flightService.errorMessage == nil {
                    flightService.errorMessage = "No flights found from \(depCode) to \(arrCode) on \(formattedSearchDate). Check the airports and date."
                }
                return
            }

            let sorted = sortFlightsByUpcoming(flights)

            flightService.isLoading = false
            availableFlights = sorted
            showFlightPicker = true
        }
    }

    private func sortFlightsByUpcoming(_ flights: [ADBFlightResponse]) -> [ADBFlightResponse] {
        flights.sorted { a, b in
            let aTime = parseDepTime(a)
            let bTime = parseDepTime(b)
            let now = Date()
            let aUpcoming = aTime.map { $0 > now } ?? false
            let bUpcoming = bTime.map { $0 > now } ?? false
            if aUpcoming != bUpcoming { return aUpcoming }
            guard let at = aTime, let bt = bTime else { return false }
            return at < bt
        }
    }

    func selectFlightFromAutocomplete(_ suggestion: FlightSuggestion) {
        searchQuery.flightNumber = suggestion.flight
        if suggestion.dep.isEmpty {
            flightService.clearAutocomplete()
            preselectedFlight = nil
            return
        }
        let flights = flightService.autocompleteFlights
        if suggestion.flightIndex < flights.count {
            preselectedFlight = flights[suggestion.flightIndex]
        } else {
            preselectedFlight = nil
        }
        flightService.clearAutocomplete()
    }

    func selectFlight(_ flight: ADBFlightResponse) async {
        showFlightPicker = false
        availableFlights = []
        currentForecast = nil
        forecastTimestamp = nil
        flightService.isLoading = true

        if !searchQuery.searchByFlightNumber, let flightNum = flight.number {
            searchQuery.searchByFlightNumber = true
            searchQuery.flightNumber = flightNum
        }

        currentForecast = await flightService.fetchForecast(query: searchQuery, selectedFlight: flight)
        handleForecastResult()
    }

    private func handleForecastResult() {
        if let forecast = currentForecast {
            forecastTimestamp = Date()
            historyService.addEntry(forecast)

            notificationService.scheduleFlightReminder(
                flightNumber: forecast.flightNumber,
                departureTime: forecast.departureTime
            )

            if forecast.overallScore <= 2 {
                showConfetti = true
            }

            writeWidgetData(forecast)
        }
        if currentForecast != nil && !subscriptionService.isSubscribed {
            showPaywall = true
        }
        if currentForecast != nil {
            forecastCount += 1
            if forecastCount == 1 && !didRateInOnboarding {
                shouldRequestReview = true
            }
        }
    }

    private var formattedSearchDate: String {
        let f = DateFormatter()
        f.dateStyle = .medium
        return f.string(from: searchQuery.date)
    }

    private func parseDepTime(_ flight: ADBFlightResponse) -> Date? {
        guard let timeStr = flight.departure?.scheduledTime?.utc ?? flight.departure?.scheduledTime?.local else { return nil }
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let d = formatter.date(from: timeStr) { return d }
        formatter.formatOptions = [.withInternetDateTime]
        if let d = formatter.date(from: timeStr) { return d }
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd HH:mmZ"
        return df.date(from: timeStr)
    }

    func dismissPaywall() {
        if isOnboardingPaywall {
            showExitIntent = true
        } else {
            showPaywall = false
        }
    }

    func dismissExitIntent() {
        showExitIntent = false
        showPaywall = false
        isOnboardingPaywall = false
    }

    func purchasePackage(_ package: Package) async {
        let success = await subscriptionService.purchase(package: package)
        if success {
            showPaywall = false
            showExitIntent = false
            isOnboardingPaywall = false
        }
    }

    private func writeWidgetData(_ forecast: FlightForecast) {
        guard let defaults = UserDefaults(suiteName: "group.app.rork.turby") else { return }
        let widgetData = WidgetForecastPayload(
            flightNumber: forecast.flightNumber,
            departureCode: forecast.departureAirport.code,
            arrivalCode: forecast.arrivalAirport.code,
            overallScore: forecast.overallScore,
            departureTime: forecast.departureTime,
            updatedAt: Date()
        )
        if let data = try? JSONEncoder().encode(widgetData) {
            defaults.set(data, forKey: "widgetForecast")
            WidgetCenter.shared.reloadAllTimelines()
        }
    }
}

nonisolated struct WidgetForecastPayload: Codable, Sendable {
    let flightNumber: String
    let departureCode: String
    let arrivalCode: String
    let overallScore: Int
    let departureTime: Date
    let updatedAt: Date
}
