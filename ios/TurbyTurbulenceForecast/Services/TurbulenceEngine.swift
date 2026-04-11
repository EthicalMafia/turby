import Foundation

struct TurbulenceAnalysis: Sendable {
    let overallScore: Int
    let takeoffScore: Int
    let climbScore: Int
    let cruiseScore: Int
    let descentScore: Int
    let landingScore: Int
    let routePointScores: [Int]
}

@MainActor
class TurbulenceEngine {

    func analyze(
        departureMetar: NOAAMetar?,
        arrivalMetar: NOAAMetar?,
        sigmets: [NOAASigmet],
        pireps: [NOAAPirep],
        gairmets: [NOAAGairmet],
        routeWind: [WindAtAltitude],
        routePoints: [(lat: Double, lon: Double)],
        cruiseAltitude: Int = 350
    ) -> TurbulenceAnalysis {
        let takeoffScore = calculateSurfaceScore(metar: departureMetar)
        let landingScore = calculateSurfaceScore(metar: arrivalMetar)

        var routePointScores: [Int] = []
        for (_, point) in routePoints.enumerated() {
            var score = 8

            if let wind = closestWind(to: point, from: routeWind) {
                score += windShearScore(wind: wind)
                score += jetStreamScore(wind: wind)
                score += temperatureGradientScore(wind: wind)
            }

            score += sigmetScore(at: point, sigmets: sigmets, cruiseAltitude: cruiseAltitude)
            score += gairmetScore(at: point, gairmets: gairmets, cruiseAltitude: cruiseAltitude)
            score += pirepScore(at: point, pireps: pireps, altitudeRange: (cruiseAltitude - 100)...(cruiseAltitude + 100))

            routePointScores.append(min(100, max(0, score)))
        }

        let cruiseScore: Int
        if routePointScores.isEmpty {
            cruiseScore = 12
        } else {
            let avg = routePointScores.reduce(0, +) / max(routePointScores.count, 1)
            let peak = routePointScores.max() ?? 0
            let p90 = percentile(routePointScores, p: 90)
            cruiseScore = min(100, (avg * 3 + p90 * 2 + peak) / 6)
        }

        let climbFinal = interpolate(surface: takeoffScore, cruise: cruiseScore, factor: 0.65)
        let descentScore = interpolate(surface: landingScore, cruise: cruiseScore, factor: 0.55)

        let overall = min(100, max(0,
            (takeoffScore * 8 + climbFinal * 12 + cruiseScore * 48 + descentScore * 12 + landingScore * 8 + p90Score(routePointScores) * 12) / 100
        ))

        return TurbulenceAnalysis(
            overallScore: overall,
            takeoffScore: takeoffScore,
            climbScore: climbFinal,
            cruiseScore: cruiseScore,
            descentScore: descentScore,
            landingScore: landingScore,
            routePointScores: routePointScores
        )
    }

    private func calculateSurfaceScore(metar: NOAAMetar?) -> Int {
        guard let metar else { return 15 }
        var score = 5

        let windSpd = metar.wspd ?? 0
        let gust = metar.wgst ?? 0

        if windSpd > 25 { score += 30 }
        else if windSpd > 15 { score += 15 }
        else if windSpd > 8 { score += 5 }

        if gust > 35 { score += 25 }
        else if gust > 20 { score += 12 }
        else if gust - windSpd > 10 { score += 8 }

        let vis = metar.visib ?? 10
        if vis < 1 { score += 10 }
        else if vis < 3 { score += 5 }

        if let wx = metar.wxString?.uppercased() {
            if wx.contains("TS") { score += 25 }
            if wx.contains("GR") { score += 15 }
            if wx.contains("SQ") { score += 20 }
            if wx.contains("FC") { score += 30 }
            if wx.contains("SH") { score += 8 }
        }

        if let clouds = metar.clouds {
            for cloud in clouds {
                if let cover = cloud.cover?.uppercased(), let base = cloud.base {
                    if cover == "CB" || cover == "TCU" { score += 20 }
                    if (cover == "BKN" || cover == "OVC") && base < 2000 { score += 5 }
                }
            }
        }

        return min(100, max(0, score))
    }

    private func windShearScore(wind: WindAtAltitude) -> Int {
        let shear300_500 = abs(wind.windSpeed300hPa - wind.windSpeed500hPa)
        let shear500_700 = abs(wind.windSpeed500hPa - wind.windSpeed700hPa)
        let maxShear = max(shear300_500, shear500_700)

        if maxShear > 60 { return 30 }
        if maxShear > 40 { return 20 }
        if maxShear > 25 { return 12 }
        if maxShear > 15 { return 5 }
        return 0
    }

    private func jetStreamScore(wind: WindAtAltitude) -> Int {
        let jetSpeed = max(wind.windSpeed300hPa, wind.windSpeed500hPa)

        if jetSpeed > 120 { return 25 }
        if jetSpeed > 90 { return 15 }
        if jetSpeed > 60 { return 8 }
        return 0
    }

    private func temperatureGradientScore(wind: WindAtAltitude) -> Int {
        let tempDiff = abs(wind.temperature300hPa - wind.temperature250hPa)
        if tempDiff > 12 { return 18 }
        if tempDiff > 8 { return 10 }
        if tempDiff > 5 { return 4 }
        return 0
    }

    private func sigmetScore(at point: (lat: Double, lon: Double), sigmets: [NOAASigmet], cruiseAltitude: Int) -> Int {
        var maxScore = 0
        let cruiseFL = cruiseAltitude
        for sigmet in sigmets {
            guard let coords = sigmet.coords, !coords.isEmpty else { continue }

            let lo = sigmet.altLo ?? 0
            let hi = sigmet.altHi ?? 999
            guard altitudeOverlaps(lo: lo, hi: hi, cruiseFL: cruiseFL) else { continue }

            if isPointNearPolygon(point: point, polygon: coords, threshold: 3.0) {
                let hazard = sigmet.hazard?.uppercased() ?? ""
                let severity = sigmet.severity?.uppercased() ?? ""

                if hazard.contains("TURB") {
                    if severity.contains("SEV") { maxScore = max(maxScore, 40) }
                    else if severity.contains("MOD") { maxScore = max(maxScore, 25) }
                    else { maxScore = max(maxScore, 15) }
                } else if hazard.contains("TS") || hazard.contains("CONVECTIVE") {
                    maxScore = max(maxScore, 30)
                } else if hazard.contains("MTN") || hazard.contains("WAVE") {
                    maxScore = max(maxScore, 20)
                } else {
                    maxScore = max(maxScore, 10)
                }
            }
        }
        return maxScore
    }

    private func gairmetScore(at point: (lat: Double, lon: Double), gairmets: [NOAAGairmet], cruiseAltitude: Int) -> Int {
        var maxScore = 0
        let cruiseFL = cruiseAltitude
        for gairmet in gairmets {
            guard let coords = gairmet.coords, !coords.isEmpty else { continue }

            let lo = gairmet.altLo ?? 0
            let hi = gairmet.altHi ?? 999
            guard altitudeOverlaps(lo: lo, hi: hi, cruiseFL: cruiseFL) else { continue }

            if isPointNearPolygon(point: point, polygon: coords, threshold: 3.0) {
                let hazard = gairmet.hazard?.uppercased() ?? ""

                if hazard.contains("TURB") || hazard.contains("TANGO") {
                    maxScore = max(maxScore, 18)
                } else if hazard.contains("ICE") || hazard.contains("ZULU") {
                    maxScore = max(maxScore, 12)
                } else if hazard.contains("LLWS") {
                    maxScore = max(maxScore, 15)
                } else {
                    maxScore = max(maxScore, 6)
                }
            }
        }
        return maxScore
    }

    private func pirepScore(at point: (lat: Double, lon: Double), pireps: [NOAAPirep], altitudeRange: ClosedRange<Int>) -> Int {
        var maxScore = 0
        for pirep in pireps {
            guard let lat = pirep.lat, let lon = pirep.lon else { continue }
            let dist = haversineDistance(lat1: point.lat, lon1: point.lon, lat2: lat, lon2: lon)
            guard dist < 200 else { continue }

            if let fl = pirep.fltLvl, fl > 0 {
                guard altitudeRange.contains(fl) else { continue }
            }

            let turb = pirep.tbInt ?? 0
            let proximityFactor = max(0.3, 1.0 - dist / 200.0)
            let baseScore: Int
            switch turb {
            case 6...: baseScore = 35
            case 4...5: baseScore = 22
            case 2...3: baseScore = 10
            default: baseScore = 0
            }
            maxScore = max(maxScore, Int(Double(baseScore) * proximityFactor))
        }
        return maxScore
    }

    private func altitudeOverlaps(lo: Int, hi: Int, cruiseFL: Int) -> Bool {
        let loFL = lo < 1000 ? lo : lo / 100
        let hiFL = hi < 1000 ? hi : hi / 100
        return loFL <= cruiseFL + 50 && hiFL >= cruiseFL - 50
    }

    private func closestWind(to point: (lat: Double, lon: Double), from winds: [WindAtAltitude]) -> WindAtAltitude? {
        winds.min(by: {
            haversineDistance(lat1: point.lat, lon1: point.lon, lat2: $0.latitude, lon2: $0.longitude) <
            haversineDistance(lat1: point.lat, lon1: point.lon, lat2: $1.latitude, lon2: $1.longitude)
        })
    }

    private func interpolate(surface: Int, cruise: Int, factor: Double) -> Int {
        Int(Double(surface) * (1.0 - factor) + Double(cruise) * factor)
    }

    private func percentile(_ values: [Int], p: Int) -> Int {
        guard !values.isEmpty else { return 0 }
        let sorted = values.sorted()
        let idx = min(sorted.count - 1, Int(Double(sorted.count) * Double(p) / 100.0))
        return sorted[idx]
    }

    private func p90Score(_ scores: [Int]) -> Int {
        percentile(scores, p: 90)
    }

    private func haversineDistance(lat1: Double, lon1: Double, lat2: Double, lon2: Double) -> Double {
        let r = 6371.0
        let dLat = (lat2 - lat1) * .pi / 180
        let dLon = (lon2 - lon1) * .pi / 180
        let a = sin(dLat/2) * sin(dLat/2) + cos(lat1 * .pi / 180) * cos(lat2 * .pi / 180) * sin(dLon/2) * sin(dLon/2)
        let c = 2 * atan2(sqrt(a), sqrt(1-a))
        return r * c
    }

    private func isPointNearPolygon(point: (lat: Double, lon: Double), polygon: [[Double]], threshold: Double) -> Bool {
        for coord in polygon {
            guard coord.count >= 2 else { continue }
            let dist = haversineDistance(lat1: point.lat, lon1: point.lon, lat2: coord[0], lon2: coord[1])
            if dist < threshold * 111 { return true }
        }
        return false
    }
}
