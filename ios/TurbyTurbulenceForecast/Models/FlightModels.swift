import Foundation
import CoreLocation

nonisolated enum PassengerProfile: String, Codable, Sendable, CaseIterable {
    case nervous
    case frequent
    case enthusiast

    var title: String {
        switch self {
        case .nervous: "Nervous Flyer"
        case .frequent: "Frequent Flyer"
        case .enthusiast: "Aviation Enthusiast"
        }
    }

    var icon: String {
        switch self {
        case .nervous: "heart.circle.fill"
        case .frequent: "briefcase.fill"
        case .enthusiast: "binoculars.fill"
        }
    }

    var subtitle: String {
        switch self {
        case .nervous: "I want calm, reassuring info"
        case .frequent: "Give me the essentials, fast"
        case .enthusiast: "Show me everything"
        }
    }

    var emoji: String {
        switch self {
        case .nervous: "😌"
        case .frequent: "✈️"
        case .enthusiast: "🔭"
        }
    }
}

nonisolated enum FlightPhase: String, Codable, Sendable, CaseIterable {
    case taxi
    case takeoff
    case climb
    case cruise
    case descent
    case approach
    case landing

    var label: String {
        switch self {
        case .taxi: "Taxi"
        case .takeoff: "Takeoff"
        case .climb: "Climb"
        case .cruise: "Cruise"
        case .descent: "Descent"
        case .approach: "Approach"
        case .landing: "Landing"
        }
    }

    var icon: String {
        switch self {
        case .taxi: "road.lanes"
        case .takeoff: "airplane.departure"
        case .climb: "arrow.up.right"
        case .cruise: "airplane"
        case .descent: "arrow.down.right"
        case .approach: "airplane.arrival"
        case .landing: "arrow.down.to.line"
        }
    }

    var approximateMinutes: (start: Int, end: Int) {
        switch self {
        case .taxi: (0, 10)
        case .takeoff: (10, 15)
        case .climb: (15, 30)
        case .cruise: (30, 70)
        case .descent: (70, 82)
        case .approach: (82, 92)
        case .landing: (92, 100)
        }
    }
}

nonisolated struct TimelineSegment: Sendable, Identifiable {
    let id: String
    let phase: FlightPhase
    let turbulence: TurbulenceLevel
    let durationPercent: Double
}

nonisolated struct SeatRecommendation: Sendable {
    let zone: String
    let row: String
    let reason: String
    let icon: String
}

nonisolated enum TurbulenceLevel: String, Codable, Sendable, CaseIterable {
    case smooth
    case light
    case moderate
    case severe

    var label: String {
        switch self {
        case .smooth: "Smooth"
        case .light: "Some bumps"
        case .moderate: "Bumpy"
        case .severe: "Very bumpy"
        }
    }

    var simpleLabel: String {
        switch self {
        case .smooth: "Smooth sailing"
        case .light: "Light bumps possible"
        case .moderate: "Expect some bumps"
        case .severe: "Hold tight"
        }
    }

    var reassurance: String {
        switch self {
        case .smooth: "Sit back and relax — your flight looks perfectly smooth."
        case .light: "Very normal. Like driving over a small speed bump. Totally safe."
        case .moderate: "This is common and expected. The plane is built to handle much more."
        case .severe: "Rare but manageable. Pilots train extensively for this. You're safe."
        }
    }

    var sensation: String {
        switch self {
        case .smooth: "Like sitting on your couch — you won't feel a thing."
        case .light: "Like driving over a speed bump. Your drink might ripple slightly."
        case .moderate: "Like a bumpy country road. You'll feel it, but it's totally normal."
        case .severe: "Like a rough boat ride. Uncomfortable but completely safe."
        }
    }

    var pilotAction: String {
        switch self {
        case .smooth: "Pilots are monitoring conditions and the route looks clear ahead."
        case .light: "Pilots may turn on the seatbelt sign as a precaution. They're fully in control."
        case .moderate: "Pilots will try to adjust altitude or route to find smoother air. This is standard procedure."
        case .severe: "Pilots will reroute or change altitude. They train for this extensively and communicate with ATC for the best path."
        }
    }

    var nervousReassurance: String {
        switch self {
        case .smooth: "Perfect conditions! Nothing to worry about at all. Enjoy your flight! 💙"
        case .light: "This is completely normal and safe. Think of it as gentle waves — the plane loves this. 💙"
        case .moderate: "We know this sounds scary, but your plane is engineered for WAY more than this. You are safe. 💙"
        case .severe: "Take a deep breath. Your pilots handle this routinely. The plane can take 1.5x more force than any turbulence. You will be okay. 💙"
        }
    }

    var icon: String {
        switch self {
        case .smooth: "checkmark.circle.fill"
        case .light: "wind"
        case .moderate: "cloud.bolt"
        case .severe: "exclamationmark.triangle.fill"
        }
    }

    var scoreRange: ClosedRange<Int> {
        switch self {
        case .smooth: 0...2
        case .light: 3...4
        case .moderate: 5...7
        case .severe: 8...10
        }
    }

    var rawScore: Int {
        switch self {
        case .smooth: 0
        case .light: 1
        case .moderate: 2
        case .severe: 3
        }
    }
}

nonisolated struct FlightSearchQuery: Sendable {
    var flightNumber: String = ""
    var departureAirport: String = ""
    var arrivalAirport: String = ""
    var date: Date = Date()
    var searchByFlightNumber: Bool = true
}

nonisolated struct Airport: Codable, Sendable, Identifiable, Hashable {
    let id: String
    let code: String
    let name: String
    let city: String
    let latitude: Double
    let longitude: Double

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

nonisolated struct WeatherCondition: Codable, Sendable, Identifiable {
    let id: String
    let temperature: Double
    let windSpeed: Double
    let windDirection: Int
    let visibility: Double
    let cloudCover: String
    let precipitation: String?
    let pressure: Double
    let humidity: Int

    var windDescription: String {
        if windSpeed < 10 { return "Calm winds" }
        if windSpeed < 20 { return "Light breeze" }
        if windSpeed < 30 { return "Moderate winds" }
        return "Strong winds"
    }

    var cloudDescription: String {
        switch cloudCover.lowercased() {
        case "clear", "skc", "clr": return "Clear skies"
        case "few": return "Mostly clear"
        case "sct", "scattered": return "Partly cloudy"
        case "bkn", "broken": return "Mostly cloudy"
        case "ovc", "overcast": return "Overcast"
        default: return "Variable clouds"
        }
    }
}

nonisolated struct RoutePoint: Codable, Sendable, Identifiable {
    let id: String
    let latitude: Double
    let longitude: Double
    let turbulenceLevel: TurbulenceLevel
    let altitude: Int

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

nonisolated struct FlightForecast: Codable, Sendable, Identifiable {
    let id: String
    let flightNumber: String
    let departureAirport: Airport
    let arrivalAirport: Airport
    let departureTime: Date
    let arrivalTime: Date
    let overallScore: Int
    let takeoffCondition: TurbulenceLevel
    let cruiseCondition: TurbulenceLevel
    let landingCondition: TurbulenceLevel
    let takeoffWeather: WeatherCondition
    let landingWeather: WeatherCondition
    let routePoints: [RoutePoint]
    let metar: String?
    let taf: String?
    let climbCondition: TurbulenceLevel
    let descentCondition: TurbulenceLevel
    let departureGate: String?
    let departureTerminal: String?
    let arrivalGate: String?
    let arrivalTerminal: String?
    let flightStatus: String?
    let aircraftModel: String?
    let aircraftReg: String?
    let regionalInsights: [TurbulenceRegionInsight]

    var overallLevel: TurbulenceLevel {
        switch overallScore {
        case 0...2: .smooth
        case 3...4: .light
        case 5...7: .moderate
        default: .severe
        }
    }

    var durationFormatted: String {
        let interval = arrivalTime.timeIntervalSince(departureTime)
        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60
        return "\(hours)h \(minutes)m"
    }

    var summaryText: String {
        let regionHint = primaryTurbulenceRegionHint
        switch overallLevel {
        case .smooth:
            return "Great news! Your flight is expected to be smooth and comfortable."
        case .light:
            return "Your flight should be mostly smooth with some light bumps\(regionHint). Nothing to worry about."
        case .moderate:
            return "Some turbulence is expected\(regionHint). This is normal — your pilots are prepared."
        case .severe:
            return "Turbulence is expected\(regionHint). Remember: planes are designed for this."
        }
    }

    private var primaryTurbulenceRegionHint: String {
        let nonSmooth = regionalInsights.filter { $0.turbulenceLevel != .smooth }
        guard let worst = nonSmooth.max(by: { $0.turbulenceLevel.rawScore < $1.turbulenceLevel.rawScore }) else { return "" }
        return ", especially over \(worst.regionName)"
    }

    var timeline: [TimelineSegment] {
        [
            TimelineSegment(id: "taxi", phase: .taxi, turbulence: .smooth, durationPercent: 0.08),
            TimelineSegment(id: "takeoff", phase: .takeoff, turbulence: takeoffCondition, durationPercent: 0.05),
            TimelineSegment(id: "climb", phase: .climb, turbulence: climbCondition, durationPercent: 0.12),
            TimelineSegment(id: "cruise", phase: .cruise, turbulence: cruiseCondition, durationPercent: 0.45),
            TimelineSegment(id: "descent", phase: .descent, turbulence: descentCondition, durationPercent: 0.12),
            TimelineSegment(id: "approach", phase: .approach, turbulence: landingCondition, durationPercent: 0.10),
            TimelineSegment(id: "landing", phase: .landing, turbulence: landingCondition, durationPercent: 0.08),
        ]
    }

    var bestSeat: SeatRecommendation {
        if overallLevel == .smooth {
            return SeatRecommendation(zone: "Window", row: "Any row", reason: "Smooth flight — pick your favorite view!", icon: "window.ceiling")
        } else {
            return SeatRecommendation(zone: "Over the wings", row: "Rows 18–26", reason: "Closest to the center of gravity — feels the least turbulence.", icon: "airplane")
        }
    }

    func summaryText(for profile: PassengerProfile) -> String {
        switch profile {
        case .nervous:
            return overallLevel.nervousReassurance
        case .frequent:
            return summaryText
        case .enthusiast:
            return "Score \(overallScore)/10 — \(overallLevel.label). Conditions driven by \(takeoffWeather.cloudDescription.lowercased()) at departure with \(takeoffWeather.windDescription.lowercased())."
        }
    }
}

