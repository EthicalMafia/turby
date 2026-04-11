import Foundation

nonisolated struct FlightSuggestion: Sendable, Identifiable {
    let flight: String
    let dep: String
    let arr: String
    let airline: String
    let depCity: String
    let arrCity: String
    let depTimeLocal: String?
    let arrTimeLocal: String?
    let status: String?
    let flightIndex: Int
    var id: String { "\(flight)_\(flightIndex)" }
}

@Observable
@MainActor
class FlightService {
    var isLoading = false
    var errorMessage: String?
    var autocompleteSuggestions: [FlightSuggestion] = []
    var autocompleteFlights: [ADBFlightResponse] = []
    var isLoadingAutocomplete = false

    private var autocompleteTask: Task<Void, Never>?
    private var lastAutocompleteQuery = ""

    private let weatherService = AviationWeatherService()
    private let meteoService = OpenMeteoService()
    private let turbulenceEngine = TurbulenceEngine()
    private let geoResolver = GeoRegionResolver()

    private var aeroDataBox: AeroDataBoxService? {
        let key = APIKeyStore.aeroDataBoxKey
        guard !key.isEmpty else { return nil }
        return AeroDataBoxService(apiKey: key)
    }

    private let airportDatabase: [String: (name: String, city: String, lat: Double, lon: Double)] = [
        "JFK": ("John F. Kennedy International", "New York", 40.6413, -73.7781),
        "LAX": ("Los Angeles International", "Los Angeles", 33.9425, -118.4081),
        "ORD": ("O'Hare International", "Chicago", 41.9742, -87.9073),
        "ATL": ("Hartsfield-Jackson International", "Atlanta", 33.6407, -84.4277),
        "DFW": ("Dallas/Fort Worth International", "Dallas", 32.8998, -97.0403),
        "SFO": ("San Francisco International", "San Francisco", 37.6213, -122.3790),
        "MIA": ("Miami International", "Miami", 25.7959, -80.2870),
        "DEN": ("Denver International", "Denver", 39.8561, -104.6737),
        "SEA": ("Seattle-Tacoma International", "Seattle", 47.4502, -122.3088),
        "IAH": ("George Bush Intercontinental", "Houston", 29.9902, -95.3368),
        "EWR": ("Newark Liberty International", "Newark", 40.6895, -74.1745),
        "BOS": ("Boston Logan International", "Boston", 42.3656, -71.0096),
        "DTW": ("Detroit Metropolitan", "Detroit", 42.2124, -83.3534),
        "MSP": ("Minneapolis-St. Paul International", "Minneapolis", 44.8848, -93.2223),
        "FLL": ("Fort Lauderdale-Hollywood International", "Fort Lauderdale", 26.0726, -80.1527),
        "MCO": ("Orlando International", "Orlando", 28.4312, -81.3081),
        "CLT": ("Charlotte Douglas International", "Charlotte", 35.2140, -80.9431),
        "PHX": ("Phoenix Sky Harbor International", "Phoenix", 33.4373, -112.0078),
        "IAD": ("Washington Dulles International", "Washington D.C.", 38.9531, -77.4565),
        "DCA": ("Ronald Reagan Washington National", "Washington D.C.", 38.8512, -77.0402),
        "SAN": ("San Diego International", "San Diego", 32.7336, -117.1897),
        "MDW": ("Chicago Midway International", "Chicago", 41.7868, -87.7522),
        "DAL": ("Dallas Love Field", "Dallas", 32.8481, -96.8512),
        "HOU": ("William P. Hobby", "Houston", 29.6454, -95.2789),
        "BWI": ("Baltimore/Washington International", "Baltimore", 39.1774, -76.6684),
        "ANC": ("Ted Stevens Anchorage International", "Anchorage", 61.1743, -149.9983),
        "LAS": ("Harry Reid International", "Las Vegas", 36.0840, -115.1537),
        "SJU": ("Luis Munoz Marin International", "San Juan", 18.4394, -66.0018),
        "CUN": ("Cancun International", "Cancun", 21.0365, -86.8771),
        "SDQ": ("Las Americas International", "Santo Domingo", 18.4297, -69.6688),
        "YYZ": ("Toronto Pearson International", "Toronto", 43.6777, -79.6248),
        "YVR": ("Vancouver International", "Vancouver", 49.1967, -123.1815),
        "LHR": ("London Heathrow", "London", 51.4700, -0.4543),
        "LGW": ("London Gatwick", "London", 51.1537, -0.1821),
        "MAN": ("Manchester Airport", "Manchester", 53.3537, -2.2750),
        "DUB": ("Dublin Airport", "Dublin", 53.4264, -6.2499),
        "CDG": ("Charles de Gaulle", "Paris", 49.0097, 2.5479),
        "FRA": ("Frankfurt Airport", "Frankfurt", 50.0379, 8.5622),
        "MUC": ("Munich Airport", "Munich", 48.3537, 11.7750),
        "AMS": ("Amsterdam Schiphol", "Amsterdam", 52.3105, 4.7683),
        "FCO": ("Leonardo da Vinci International", "Rome", 41.8003, 12.2389),
        "MAD": ("Adolfo Suarez Madrid-Barajas", "Madrid", 40.4936, -3.5668),
        "BCN": ("Barcelona El Prat", "Barcelona", 41.2974, 2.0833),
        "ZRH": ("Zurich Airport", "Zurich", 47.4647, 8.5492),
        "IST": ("Istanbul Airport", "Istanbul", 41.2619, 28.7419),
        "DXB": ("Dubai International", "Dubai", 25.2532, 55.3657),
        "AUH": ("Abu Dhabi International", "Abu Dhabi", 24.4330, 54.6511),
        "DOH": ("Hamad International", "Doha", 25.2609, 51.6138),
        "NRT": ("Narita International", "Tokyo", 35.7720, 140.3929),
        "HND": ("Haneda Airport", "Tokyo", 35.5494, 139.7798),
        "ICN": ("Incheon International", "Seoul", 37.4602, 126.4407),
        "SIN": ("Singapore Changi", "Singapore", 1.3644, 103.9915),
        "HKG": ("Hong Kong International", "Hong Kong", 22.3080, 113.9185),
        "PVG": ("Shanghai Pudong International", "Shanghai", 31.1443, 121.8083),
        "PEK": ("Beijing Capital International", "Beijing", 40.0799, 116.6031),
        "TPE": ("Taiwan Taoyuan International", "Taipei", 25.0797, 121.2342),
        "BKK": ("Suvarnabhumi Airport", "Bangkok", 13.6900, 100.7501),
        "DEL": ("Indira Gandhi International", "New Delhi", 28.5562, 77.1000),
        "BOM": ("Chhatrapati Shivaji International", "Mumbai", 19.0896, 72.8656),
        "SYD": ("Sydney Kingsford Smith", "Sydney", -33.9461, 151.1772),
        "MEL": ("Melbourne Airport", "Melbourne", -37.6690, 144.8410),
        "AKL": ("Auckland Airport", "Auckland", -37.0082, 174.7850),
        "GRU": ("Sao Paulo-Guarulhos International", "Sao Paulo", -23.4356, -46.4731),
        "EZE": ("Ministro Pistarini International", "Buenos Aires", -34.8222, -58.5358),
        "SCL": ("Santiago International", "Santiago", -33.3930, -70.7858),
        "LIM": ("Jorge Chavez International", "Lima", -12.0219, -77.1143),
        "BOG": ("El Dorado International", "Bogota", 4.7016, -74.1469),
        "PTY": ("Tocumen International", "Panama City", 9.0714, -79.3835),
        "JNB": ("O.R. Tambo International", "Johannesburg", -26.1392, 28.2460),
    ]

    private var knownAirlineCodes: Set<String> {
        Set(AirlineDatabase.allAirlines.map { $0.iata })
    }

    func updateAutocomplete(for input: String, date: Date) {
        let cleaned = input.uppercased().trimmingCharacters(in: .whitespaces).replacingOccurrences(of: " ", with: "")

        guard cleaned.count >= 2 else {
            autocompleteTask?.cancel()
            autocompleteSuggestions = []
            isLoadingAutocomplete = false
            lastAutocompleteQuery = ""
            return
        }

        let parsed = parseAirlineAndNumber(cleaned)
        guard !parsed.airline.isEmpty else {
            autocompleteSuggestions = []
            return
        }

        let airlineCode = parsed.airline.count == 3 ? String(parsed.airline.prefix(2)) : parsed.airline
        let airlineName = AirlineDatabase.allAirlines.first(where: { $0.iata == airlineCode })?.name ?? ""

        if !airlineName.isEmpty && parsed.number.isEmpty {
            autocompleteSuggestions = [
                FlightSuggestion(flight: airlineCode, dep: "", arr: "", airline: "\(airlineName) — type flight number", depCity: "", arrCity: "", depTimeLocal: nil, arrTimeLocal: nil, status: nil, flightIndex: 0)
            ]
            return
        }

        guard !parsed.number.isEmpty, !airlineName.isEmpty else {
            autocompleteSuggestions = []
            return
        }

        let queryKey = "\(airlineCode)\(parsed.number)"
        guard queryKey != lastAutocompleteQuery else { return }
        lastAutocompleteQuery = queryKey

        autocompleteTask?.cancel()
        autocompleteTask = Task {
            isLoadingAutocomplete = true
            defer { isLoadingAutocomplete = false }

            try? await Task.sleep(for: .milliseconds(400))
            guard !Task.isCancelled else { return }

            guard let service = aeroDataBox else { return }

            do {
                let flightNumber = "\(airlineCode)\(parsed.number)"
                let flights = try await service.fetchFlightStatus(flightNumber: flightNumber, date: date)
                guard !Task.isCancelled else { return }

                let sorted = flights.sorted { a, b in
                    let aTime = self.parseADBTime(a.departure?.scheduledTime?.utc ?? a.departure?.scheduledTime?.local)
                    let bTime = self.parseADBTime(b.departure?.scheduledTime?.utc ?? b.departure?.scheduledTime?.local)
                    let now = Date()
                    let aUpcoming = aTime.map { $0 > now } ?? false
                    let bUpcoming = bTime.map { $0 > now } ?? false
                    if aUpcoming != bUpcoming { return aUpcoming }
                    guard let at = aTime, let bt = bTime else { return false }
                    return at < bt
                }
                autocompleteSuggestions = sorted.prefix(8).enumerated().compactMap { index, flight in
                    guard let depIata = flight.departure?.airport?.iata,
                          let arrIata = flight.arrival?.airport?.iata else { return nil }
                    return FlightSuggestion(
                        flight: flight.number ?? flightNumber,
                        dep: depIata,
                        arr: arrIata,
                        airline: flight.airline?.name ?? airlineName,
                        depCity: flight.departure?.airport?.municipalityName ?? "",
                        arrCity: flight.arrival?.airport?.municipalityName ?? "",
                        depTimeLocal: flight.departure?.scheduledTime?.local ?? flight.departure?.scheduledTime?.utc,
                        arrTimeLocal: flight.arrival?.scheduledTime?.local ?? flight.arrival?.scheduledTime?.utc,
                        status: flight.status,
                        flightIndex: index
                    )
                }
                autocompleteFlights = Array(sorted.prefix(8))
            } catch {
                guard !Task.isCancelled else { return }
                autocompleteSuggestions = []
            }
        }
    }

    func clearAutocomplete() {
        autocompleteTask?.cancel()
        autocompleteSuggestions = []
        autocompleteFlights = []
        isLoadingAutocomplete = false
        lastAutocompleteQuery = ""
    }

    func validateFlightNumber(_ input: String) -> String? {
        let cleaned = input.uppercased().trimmingCharacters(in: .whitespaces).replacingOccurrences(of: " ", with: "")
        guard !cleaned.isEmpty else { return "Please enter a flight number." }

        let parsed = parseAirlineAndNumber(cleaned)
        guard !parsed.airline.isEmpty else { return "Flight number must start with an airline code (e.g. AA, UA, DL)." }
        guard parsed.airline.count >= 2, parsed.airline.count <= 3 else { return "Invalid airline code. Use 2-3 letters (e.g. AA, UAL)." }
        guard !parsed.number.isEmpty else { return "Flight number must include a number (e.g. AA1234)." }
        guard parsed.number.count <= 4 else { return "Flight number too long. Use 1-4 digits (e.g. AA1234)." }

        let airlineCode = parsed.airline.count == 3 ? String(parsed.airline.prefix(2)) : parsed.airline
        guard knownAirlineCodes.contains(airlineCode) else {
            return "\"\(airlineCode)\" is not a recognized airline code."
        }

        return nil
    }

    func fetchForecast(query: FlightSearchQuery, selectedFlight: ADBFlightResponse? = nil) async -> FlightForecast? {
        isLoading = true
        defer { isLoading = false }
        errorMessage = nil

        if query.searchByFlightNumber {
            if let validationError = validateFlightNumber(query.flightNumber) {
                errorMessage = validationError
                return nil
            }
        }

        let depCode: String
        let arrCode: String
        var depLat: Double?
        var depLon: Double?
        var arrLat: Double?
        var arrLon: Double?
        var depName: String?
        var arrName: String?
        var depCity: String?
        var arrCity: String?
        var scheduledDep: Date?
        var scheduledArr: Date?
        var flightStatus: String?
        var depGate: String?
        var depTerminal: String?
        var arrGate: String?
        var arrTerminal: String?
        var aircraftModel: String?
        var aircraftReg: String?

        if query.searchByFlightNumber {
            let flightData = selectedFlight

            if let flight = flightData {
                depCode = flight.departure?.airport?.iata ?? "???"
                arrCode = flight.arrival?.airport?.iata ?? "???"
                depLat = flight.departure?.airport?.location?.lat
                depLon = flight.departure?.airport?.location?.lon
                arrLat = flight.arrival?.airport?.location?.lat
                arrLon = flight.arrival?.airport?.location?.lon
                depName = flight.departure?.airport?.name
                arrName = flight.arrival?.airport?.name
                depCity = flight.departure?.airport?.municipalityName
                arrCity = flight.arrival?.airport?.municipalityName
                flightStatus = flight.status
                depGate = flight.departure?.gate
                depTerminal = flight.departure?.terminal
                arrGate = flight.arrival?.gate
                arrTerminal = flight.arrival?.terminal
                aircraftModel = flight.aircraft?.model
                aircraftReg = flight.aircraft?.reg
                scheduledDep = parseADBTime(flight.departure?.scheduledTime?.utc ?? flight.departure?.scheduledTime?.local)
                scheduledArr = parseADBTime(flight.arrival?.scheduledTime?.utc ?? flight.arrival?.scheduledTime?.local)
            } else {
                if aeroDataBox != nil {
                    errorMessage = "No flight found for that number on \(formattedDate(query.date)). Check the flight number and date."
                    return nil
                } else {
                    errorMessage = "Flight data API not configured. Add your AeroDataBox API key in Settings."
                    return nil
                }
            }
        } else {
            depCode = query.departureAirport.uppercased().trimmingCharacters(in: .whitespaces)
            arrCode = query.arrivalAirport.uppercased().trimmingCharacters(in: .whitespaces)
            guard !depCode.isEmpty, !arrCode.isEmpty else {
                errorMessage = "Please enter both departure and arrival airports."
                return nil
            }
        }

        let departure = buildAirport(
            code: depCode,
            name: depName,
            city: depCity,
            lat: depLat,
            lon: depLon
        )
        let arrival = buildAirport(
            code: arrCode,
            name: arrName,
            city: arrCity,
            lat: arrLat,
            lon: arrLon
        )

        let depTime = scheduledDep ?? query.date
        let arrTime = scheduledArr ?? query.date.addingTimeInterval(estimateFlightDuration(from: departure, to: arrival))

        let routeLatLons = generateRouteLatLons(from: departure, to: arrival, count: 12)

        async let depMetarTask = weatherService.fetchMetar(station: depCode)
        async let arrMetarTask = weatherService.fetchMetar(station: arrCode)
        async let depTafTask = weatherService.fetchTaf(station: depCode)
        async let sigmetsTask = weatherService.fetchSigmets()
        async let pirepsTask = weatherService.fetchPireps(hours: 6)
        async let gairmetsTask = weatherService.fetchGairmets()
        async let routeWindTask = meteoService.fetchWindAlongRoute(points: routeLatLons)

        let depMetar = await depMetarTask
        let arrMetar = await arrMetarTask
        let depTaf = await depTafTask
        let sigmets = await sigmetsTask
        let pireps = await pirepsTask
        let gairmets = await gairmetsTask
        let routeWind = await routeWindTask

        let analysis = turbulenceEngine.analyze(
            departureMetar: depMetar,
            arrivalMetar: arrMetar,
            sigmets: sigmets,
            pireps: pireps,
            gairmets: gairmets,
            routeWind: routeWind,
            routePoints: routeLatLons
        )

        let routePoints = buildRoutePoints(latLons: routeLatLons, scores: analysis.routePointScores)

        let regionalInsights = geoResolver.resolveRegions(
            routePoints: routeLatLons,
            scores: analysis.routePointScores,
            departure: (lat: departure.latitude, lon: departure.longitude),
            arrival: (lat: arrival.latitude, lon: arrival.longitude)
        )

        let flightNum = query.searchByFlightNumber
            ? query.flightNumber.uppercased().trimmingCharacters(in: .whitespaces).replacingOccurrences(of: " ", with: "")
            : "\(depCode)-\(arrCode)"

        let displayScore = min(10, max(0, (analysis.overallScore + 5) / 10))

        let forecast = FlightForecast(
            id: UUID().uuidString,
            flightNumber: flightNum,
            departureAirport: departure,
            arrivalAirport: arrival,
            departureTime: depTime,
            arrivalTime: arrTime,
            overallScore: displayScore,
            takeoffCondition: turbulenceForScore(analysis.takeoffScore),
            cruiseCondition: turbulenceForScore(analysis.cruiseScore),
            landingCondition: turbulenceForScore(analysis.landingScore),
            takeoffWeather: metarToWeather(depMetar, fallbackCode: depCode),
            landingWeather: metarToWeather(arrMetar, fallbackCode: arrCode),
            routePoints: routePoints,
            metar: depMetar?.rawOb,
            taf: depTaf?.rawTAF,
            climbCondition: turbulenceForScore(analysis.climbScore),
            descentCondition: turbulenceForScore(analysis.descentScore),
            departureGate: depGate,
            departureTerminal: depTerminal,
            arrivalGate: arrGate,
            arrivalTerminal: arrTerminal,
            flightStatus: flightStatus,
            aircraftModel: aircraftModel,
            aircraftReg: aircraftReg,
            regionalInsights: regionalInsights
        )

        return forecast
    }

    func fetchAllFlightsFromAPI(flightNumber: String, date: Date) async -> [ADBFlightResponse] {
        guard let service = aeroDataBox else { return [] }

        do {
            let flights = try await service.fetchFlightStatus(flightNumber: flightNumber, date: date)
            return flights
        } catch {
            if let adbError = error as? ADBError {
                errorMessage = adbError.errorDescription
            }
            return []
        }
    }

    func fetchFlightsByRoute(departureIata: String, arrivalIata: String, date: Date) async -> [ADBFlightResponse] {
        guard let service = aeroDataBox else {
            errorMessage = "Flight data API not configured. Add your AeroDataBox API key in Settings."
            return []
        }

        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? date

        do {
            let departures = try await service.fetchDepartures(airportIata: departureIata, from: startOfDay, to: endOfDay)
            let filtered = departures.filter { flight in
                guard let arrIata = flight.arrival?.airport?.iata else { return false }
                return arrIata.uppercased() == arrivalIata.uppercased()
            }
            return filtered
        } catch {
            if let adbError = error as? ADBError {
                errorMessage = adbError.errorDescription
            }
            return []
        }
    }

    private func buildAirport(code: String, name: String?, city: String?, lat: Double?, lon: Double?) -> Airport {
        let fallback = airportDatabase[code]
        return Airport(
            id: code,
            code: code,
            name: name ?? fallback?.name ?? "\(code) Airport",
            city: city ?? fallback?.city ?? code,
            latitude: lat ?? fallback?.lat ?? 0,
            longitude: lon ?? fallback?.lon ?? 0
        )
    }

    private func generateRouteLatLons(from departure: Airport, to arrival: Airport, count: Int) -> [(lat: Double, lon: Double)] {
        let lat1 = departure.latitude * .pi / 180
        let lon1 = departure.longitude * .pi / 180
        let lat2 = arrival.latitude * .pi / 180
        let lon2 = arrival.longitude * .pi / 180

        let dLon = lon2 - lon1
        let cosLat2 = cos(lat2)
        let sinLat2 = sin(lat2)
        let cosLat1 = cos(lat1)
        let sinLat1 = sin(lat1)

        let d = 2 * asin(sqrt(
            pow(sin((lat2 - lat1) / 2), 2) + cosLat1 * cosLat2 * pow(sin(dLon / 2), 2)
        ))

        guard d > 0.001 else {
            return (0..<count).map { _ in (lat: departure.latitude, lon: departure.longitude) }
        }

        var points: [(lat: Double, lon: Double)] = []
        for i in 0..<count {
            let f = Double(i) / Double(count - 1)
            let a = sin((1 - f) * d) / sin(d)
            let b = sin(f * d) / sin(d)
            let x = a * cosLat1 * cos(lon1) + b * cosLat2 * cos(lon2)
            let y = a * cosLat1 * sin(lon1) + b * cosLat2 * sin(lon2)
            let z = a * sinLat1 + b * sinLat2
            let lat = atan2(z, sqrt(x * x + y * y)) * 180 / .pi
            let lon = atan2(y, x) * 180 / .pi
            points.append((lat: lat, lon: lon))
        }
        return points
    }

    private func buildRoutePoints(latLons: [(lat: Double, lon: Double)], scores: [Int]) -> [RoutePoint] {
        var points: [RoutePoint] = []
        for (i, ll) in latLons.enumerated() {
            let score = scores[safe: i] ?? 10
            points.append(RoutePoint(
                id: UUID().uuidString,
                latitude: ll.lat,
                longitude: ll.lon,
                turbulenceLevel: turbulenceForScore(score),
                altitude: 35000
            ))
        }
        return points
    }

    private func metarToWeather(_ metar: NOAAMetar?, fallbackCode: String) -> WeatherCondition {
        guard let m = metar else {
            return WeatherCondition(
                id: UUID().uuidString,
                temperature: 20,
                windSpeed: 5,
                windDirection: 0,
                visibility: 10,
                cloudCover: "CLR",
                precipitation: nil,
                pressure: 1013,
                humidity: 50
            )
        }

        let cloudCover: String
        if let clouds = m.clouds, let first = clouds.first, let cover = first.cover {
            cloudCover = cover
        } else {
            cloudCover = "CLR"
        }

        return WeatherCondition(
            id: UUID().uuidString,
            temperature: m.temp ?? 20,
            windSpeed: Double(m.wspd ?? 5),
            windDirection: m.wdir ?? 0,
            visibility: m.visib ?? 10,
            cloudCover: cloudCover,
            precipitation: m.wxString,
            pressure: m.slp ?? m.altim ?? 1013,
            humidity: Int(m.humid ?? 50)
        )
    }

    private func turbulenceForScore(_ score: Int) -> TurbulenceLevel {
        switch score {
        case 0...20: return .smooth
        case 21...45: return .light
        case 46...70: return .moderate
        default: return .severe
        }
    }

    private func displayTurbulenceForScore(_ score: Int) -> TurbulenceLevel {
        switch score {
        case 0...2: return .smooth
        case 3...4: return .light
        case 5...7: return .moderate
        default: return .severe
        }
    }

    private func estimateFlightDuration(from dep: Airport, to arr: Airport) -> TimeInterval {
        let r = 6371.0
        let dLat = (arr.latitude - dep.latitude) * .pi / 180
        let dLon = (arr.longitude - dep.longitude) * .pi / 180
        let a = sin(dLat/2) * sin(dLat/2) + cos(dep.latitude * .pi / 180) * cos(arr.latitude * .pi / 180) * sin(dLon/2) * sin(dLon/2)
        let c = 2 * atan2(sqrt(a), sqrt(1-a))
        let distKm = r * c
        let speedKmh = 850.0
        let hours = distKm / speedKmh
        return max(hours * 3600 + 1800, 3600)
    }

    private func parseAirlineAndNumber(_ input: String) -> (airline: String, number: String) {
        let cleaned = input.uppercased().trimmingCharacters(in: .whitespaces).replacingOccurrences(of: " ", with: "")
        var airline = ""
        var number = ""
        for char in cleaned {
            if char.isLetter {
                if number.isEmpty {
                    airline.append(char)
                }
            } else if char.isNumber {
                number.append(char)
            }
        }
        return (airline, number)
    }

    private func parseADBTime(_ timeStr: String?) -> Date? {
        guard let timeStr else { return nil }
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let d = formatter.date(from: timeStr) { return d }
        formatter.formatOptions = [.withInternetDateTime]
        if let d = formatter.date(from: timeStr) { return d }
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd HH:mmZ"
        return df.date(from: timeStr)
    }

    func fetchTimeShiftedScore(forecast: FlightForecast, hourOffset: Int) async -> Int {
        let routeLatLons = generateRouteLatLons(from: forecast.departureAirport, to: forecast.arrivalAirport, count: 8)
        let routeWind = await meteoService.fetchWindAlongRoute(points: routeLatLons, hourOffset: hourOffset)

        let analysis = turbulenceEngine.analyze(
            departureMetar: nil,
            arrivalMetar: nil,
            sigmets: [],
            pireps: [],
            gairmets: [],
            routeWind: routeWind,
            routePoints: routeLatLons
        )

        return min(10, max(0, (analysis.overallScore + 5) / 10))
    }

    private func formattedDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateStyle = .medium
        return f.string(from: date)
    }
}
