import Foundation

nonisolated struct TurbulenceRegionInsight: Codable, Sendable, Identifiable {
    let id: String
    let regionName: String
    let turbulenceLevel: TurbulenceLevel
    let latitude: Double
    let longitude: Double
    let distanceFromDeparture: Double
    let flightProgressPercent: Double
}

class GeoRegionResolver {

    private static let regions: [(name: String, lat: Double, lon: Double, radius: Double)] = [
        ("New England", 43.0, -71.5, 250),
        ("New York", 42.0, -75.0, 200),
        ("New Jersey", 40.2, -74.5, 100),
        ("Pennsylvania", 41.0, -77.5, 200),
        ("Virginia", 37.5, -79.0, 200),
        ("North Carolina", 35.5, -79.5, 250),
        ("South Carolina", 33.8, -80.8, 150),
        ("Georgia", 32.7, -83.5, 200),
        ("Florida", 28.0, -82.0, 350),
        ("Alabama", 32.8, -86.8, 150),
        ("Mississippi", 32.7, -89.7, 150),
        ("Tennessee", 35.8, -86.3, 200),
        ("Kentucky", 37.8, -85.7, 200),
        ("Ohio", 40.4, -82.7, 200),
        ("Michigan", 44.3, -84.5, 250),
        ("Indiana", 39.8, -86.1, 150),
        ("Illinois", 40.6, -89.3, 200),
        ("Wisconsin", 44.5, -89.8, 200),
        ("Minnesota", 46.0, -94.3, 250),
        ("Iowa", 42.0, -93.5, 200),
        ("Missouri", 38.6, -92.6, 200),
        ("Arkansas", 34.8, -92.2, 150),
        ("Louisiana", 31.0, -92.0, 200),
        ("Texas", 31.5, -99.0, 500),
        ("Oklahoma", 35.5, -97.5, 200),
        ("Kansas", 38.5, -98.3, 250),
        ("Nebraska", 41.5, -99.8, 250),
        ("South Dakota", 44.5, -100.2, 200),
        ("North Dakota", 47.5, -100.5, 200),
        ("Montana", 47.0, -109.6, 300),
        ("Wyoming", 43.0, -107.5, 250),
        ("Colorado", 39.0, -105.5, 250),
        ("New Mexico", 34.5, -106.0, 250),
        ("Arizona", 34.2, -111.6, 250),
        ("Utah", 39.3, -111.7, 200),
        ("Nevada", 39.5, -116.8, 250),
        ("Idaho", 44.0, -114.7, 250),
        ("Oregon", 44.0, -120.5, 250),
        ("Washington", 47.5, -120.7, 250),
        ("California", 37.0, -119.5, 400),

        ("Southern Ontario", 44.0, -79.5, 250),
        ("Quebec", 47.0, -71.0, 400),
        ("British Columbia", 53.0, -125.0, 500),
        ("Alberta", 53.5, -114.0, 400),
        ("Manitoba", 50.0, -98.0, 350),
        ("Saskatchewan", 52.0, -106.0, 400),
        ("the Maritimes", 46.0, -63.0, 300),

        ("Southern England", 51.5, -1.0, 200),
        ("Northern England", 54.0, -1.5, 200),
        ("Scotland", 56.5, -4.0, 250),
        ("Wales", 52.0, -3.5, 150),
        ("Ireland", 53.4, -8.0, 250),
        ("Northern France", 49.0, 2.5, 250),
        ("Southern France", 44.0, 2.5, 300),
        ("the Bay of Biscay", 45.0, -4.0, 300),
        ("the Netherlands", 52.2, 5.3, 150),
        ("Belgium", 50.8, 4.4, 100),
        ("Western Germany", 50.5, 7.5, 250),
        ("Eastern Germany", 51.5, 12.5, 200),
        ("Southern Germany", 48.5, 11.0, 200),
        ("Switzerland", 46.8, 8.2, 150),
        ("Austria", 47.3, 13.3, 200),
        ("Northern Italy", 45.0, 11.0, 250),
        ("Central Italy", 42.5, 12.5, 200),
        ("Southern Italy", 40.0, 16.0, 250),
        ("Spain", 40.0, -3.5, 400),
        ("Portugal", 39.5, -8.0, 200),
        ("the Czech Republic", 49.8, 15.5, 150),
        ("Poland", 52.0, 20.0, 300),
        ("Hungary", 47.5, 19.0, 150),
        ("Romania", 46.0, 25.0, 250),
        ("Greece", 39.0, 22.0, 250),
        ("the Balkans", 43.5, 20.0, 300),
        ("Turkey", 39.5, 32.5, 500),
        ("Scandinavia", 62.0, 15.0, 500),
        ("Denmark", 56.0, 9.5, 150),
        ("Finland", 64.0, 26.0, 400),
        ("the Baltic states", 57.0, 24.0, 250),
        ("Ukraine", 49.0, 32.0, 400),

        ("the North Atlantic", 52.0, -30.0, 1200),
        ("the Mid-Atlantic", 38.0, -45.0, 800),
        ("Iceland", 65.0, -18.0, 300),
        ("the Azores", 38.5, -28.0, 300),

        ("the Arabian Peninsula", 23.0, 45.0, 700),
        ("the Persian Gulf", 27.0, 51.0, 400),
        ("Iran", 32.0, 53.0, 600),
        ("Egypt", 26.0, 30.0, 500),
        ("North Africa", 30.0, 5.0, 800),
        ("East Africa", 0.0, 37.0, 600),
        ("Southern Africa", -25.0, 28.0, 600),
        ("West Africa", 10.0, -5.0, 700),

        ("Central Asia", 42.0, 65.0, 800),
        ("Northern India", 28.0, 78.0, 500),
        ("Southern India", 15.0, 78.0, 500),
        ("Southeast Asia", 10.0, 105.0, 800),
        ("Eastern China", 35.0, 117.0, 600),
        ("Western China", 36.0, 100.0, 800),
        ("Japan", 36.0, 138.0, 400),
        ("South Korea", 36.5, 128.0, 200),
        ("the Philippines", 12.0, 122.0, 400),
        ("Indonesia", -2.0, 115.0, 800),

        ("Eastern Australia", -30.0, 150.0, 600),
        ("Western Australia", -25.0, 125.0, 800),
        ("New Zealand", -41.0, 174.0, 400),

        ("the Caribbean", 18.0, -72.0, 600),
        ("Central America", 12.0, -85.0, 500),
        ("Northern Mexico", 28.0, -105.0, 400),
        ("Southern Mexico", 18.0, -98.0, 400),
        ("Brazil", -10.0, -52.0, 1000),
        ("Argentina", -35.0, -64.0, 600),
        ("Colombia", 4.5, -74.0, 400),
        ("Peru", -10.0, -76.0, 400),
        ("Chile", -33.0, -70.5, 500),

        ("the Pacific Ocean", 15.0, -160.0, 2000),
        ("the South Pacific", -20.0, -150.0, 2000),
        ("the Indian Ocean", -10.0, 70.0, 1500),
    ]

    func resolveRegions(
        routePoints: [(lat: Double, lon: Double)],
        scores: [Int],
        departure: (lat: Double, lon: Double),
        arrival: (lat: Double, lon: Double)
    ) -> [TurbulenceRegionInsight] {
        guard !routePoints.isEmpty else { return [] }

        let totalDistance = haversineDistance(
            lat1: departure.lat, lon1: departure.lon,
            lat2: arrival.lat, lon2: arrival.lon
        )

        var insights: [TurbulenceRegionInsight] = []
        var usedRegions: Set<String> = []

        let skipFirst = max(1, routePoints.count / 8)
        let skipLast = max(1, routePoints.count / 8)
        let midPoints = Array(routePoints.enumerated()).filter { i, _ in
            i >= skipFirst && i < routePoints.count - skipLast
        }

        for (index, point) in midPoints {
            let score = scores[safe: index] ?? 10
            let level = turbulenceLevelForRawScore(score)
            guard level != .smooth else { continue }

            guard let regionName = closestRegion(lat: point.lat, lon: point.lon) else { continue }
            guard !usedRegions.contains(regionName) else { continue }
            usedRegions.insert(regionName)

            let distFromDep = haversineDistance(
                lat1: departure.lat, lon1: departure.lon,
                lat2: point.lat, lon2: point.lon
            )
            let progress = totalDistance > 0 ? distFromDep / totalDistance : 0.5

            insights.append(TurbulenceRegionInsight(
                id: "\(regionName)-\(index)",
                regionName: regionName,
                turbulenceLevel: level,
                latitude: point.lat,
                longitude: point.lon,
                distanceFromDeparture: distFromDep,
                flightProgressPercent: progress
            ))
        }

        return insights.sorted { $0.flightProgressPercent < $1.flightProgressPercent }
    }

    private func closestRegion(lat: Double, lon: Double) -> String? {
        var bestRegion: String?
        var bestScore = Double.infinity

        for region in Self.regions {
            let dist = haversineDistance(lat1: lat, lon1: lon, lat2: region.lat, lon2: region.lon)
            guard dist < region.radius else { continue }
            let score = dist / region.radius
            if score < bestScore {
                bestScore = score
                bestRegion = region.name
            }
        }

        return bestRegion
    }

    private func turbulenceLevelForRawScore(_ score: Int) -> TurbulenceLevel {
        switch score {
        case 0...20: return .smooth
        case 21...45: return .light
        case 46...70: return .moderate
        default: return .severe
        }
    }

    private func haversineDistance(lat1: Double, lon1: Double, lat2: Double, lon2: Double) -> Double {
        let r = 6371.0
        let dLat = (lat2 - lat1) * .pi / 180
        let dLon = (lon2 - lon1) * .pi / 180
        let a = sin(dLat/2) * sin(dLat/2) + cos(lat1 * .pi / 180) * cos(lat2 * .pi / 180) * sin(dLon/2) * sin(dLon/2)
        let c = 2 * atan2(sqrt(a), sqrt(1-a))
        return r * c
    }
}

