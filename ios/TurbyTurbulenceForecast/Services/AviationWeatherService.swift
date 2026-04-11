import Foundation

nonisolated struct NOAAMetar: Codable, Sendable {
    let rawOb: String?
    let temp: Double?
    let dewp: Double?
    let wdir: Int?
    let wspd: Int?
    let wgst: Int?
    let visib: Double?
    let altim: Double?
    let fltcat: String?
    let clouds: [NOAACloud]?
    let wxString: String?
    let name: String?
    let icaoId: String?
    let reportTime: String?
    let humid: Double?
    let slp: Double?
}

nonisolated struct NOAACloud: Codable, Sendable {
    let cover: String?
    let base: Int?
}

nonisolated struct NOAATaf: Codable, Sendable {
    let rawTAF: String?
    let icaoId: String?
    let name: String?
    let issueTime: String?
    let validTimeFrom: Int?
    let validTimeTo: Int?
    let fcsts: [NOAATafForecast]?
}

nonisolated struct NOAATafForecast: Codable, Sendable {
    let timeFrom: Int?
    let timeTo: Int?
    let wdir: Int?
    let wspd: Int?
    let wgst: Int?
    let visib: Double?
    let clouds: [NOAACloud]?
    let wxString: String?
    let fltcat: String?
}

nonisolated struct NOAASigmet: Codable, Sendable {
    let rawSigmet: String?
    let hazard: String?
    let severity: String?
    let altLo: Int?
    let altHi: Int?
    let validTimeFrom: String?
    let validTimeTo: String?
    let coords: [[Double]]?
    let icaoId: String?
}

nonisolated struct NOAAPirep: Codable, Sendable {
    let rawOb: String?
    let lat: Double?
    let lon: Double?
    let fltLvl: Int?
    let tbInt: Int?
    let icInt: Int?
    let reportTime: String?
}

nonisolated struct NOAAGairmet: Codable, Sendable {
    let data: String?
    let hazard: String?
    let severity: String?
    let altLo: Int?
    let altHi: Int?
    let dueTo: String?
    let validTimeFrom: String?
    let validTimeTo: String?
    let coords: [[Double]]?
}

@MainActor
class AviationWeatherService {
    private let baseURL = "https://aviationweather.gov/api/data"

    func fetchMetar(station: String) async -> NOAAMetar? {
        let icao = toICAO(station)
        guard let url = URL(string: "\(baseURL)/metar?ids=\(icao)&format=json") else { return nil }

        do {
            var request = URLRequest(url: url)
            request.timeoutInterval = 10
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else { return nil }
            let metars = try JSONDecoder().decode([NOAAMetar].self, from: data)
            return metars.first
        } catch {
            return nil
        }
    }

    func fetchTaf(station: String) async -> NOAATaf? {
        let icao = toICAO(station)
        guard let url = URL(string: "\(baseURL)/taf?ids=\(icao)&format=json") else { return nil }

        do {
            var request = URLRequest(url: url)
            request.timeoutInterval = 10
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else { return nil }
            let tafs = try JSONDecoder().decode([NOAATaf].self, from: data)
            return tafs.first
        } catch {
            return nil
        }
    }

    func fetchSigmets() async -> [NOAASigmet] {
        guard let url = URL(string: "\(baseURL)/airsigmet?format=json&type=sigmet") else { return [] }

        do {
            var request = URLRequest(url: url)
            request.timeoutInterval = 10
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else { return [] }
            let sigmets = try JSONDecoder().decode([NOAASigmet].self, from: data)
            return sigmets
        } catch {
            return []
        }
    }

    func fetchPireps(hours: Int = 6) async -> [NOAAPirep] {
        guard let url = URL(string: "\(baseURL)/pirep?format=json&age=\(hours)") else { return [] }

        do {
            var request = URLRequest(url: url)
            request.timeoutInterval = 10
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else { return [] }
            let pireps = try JSONDecoder().decode([NOAAPirep].self, from: data)
            return pireps
        } catch {
            return []
        }
    }

    func fetchGairmets() async -> [NOAAGairmet] {
        guard let url = URL(string: "\(baseURL)/airsigmet?format=json&type=gairmet") else { return [] }

        do {
            var request = URLRequest(url: url)
            request.timeoutInterval = 10
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else { return [] }
            let gairmets = try JSONDecoder().decode([NOAAGairmet].self, from: data)
            return gairmets
        } catch {
            return []
        }
    }

    private static let iataToICAO: [String: String] = [
        "JFK": "KJFK", "LAX": "KLAX", "ORD": "KORD", "ATL": "KATL",
        "DFW": "KDFW", "SFO": "KSFO", "MIA": "KMIA", "DEN": "KDEN",
        "SEA": "KSEA", "IAH": "KIAH", "EWR": "KEWR", "BOS": "KBOS",
        "DTW": "KDTW", "MSP": "KMSP", "FLL": "KFLL", "MCO": "KMCO",
        "CLT": "KCLT", "PHX": "KPHX", "IAD": "KIAD", "DCA": "KDCA",
        "SAN": "KSAN", "MDW": "KMDW", "DAL": "KDAL", "HOU": "KHOU",
        "BWI": "KBWI", "ANC": "PANC", "LAS": "KLAS",
        "SJU": "TJSJ",
        "CUN": "MMUN", "SDQ": "MDSD",
        "YYZ": "CYYZ", "YVR": "CYVR",
        "LHR": "EGLL", "LGW": "EGKK", "MAN": "EGCC",
        "DUB": "EIDW",
        "CDG": "LFPG",
        "FRA": "EDDF", "MUC": "EDDM",
        "AMS": "EHAM",
        "FCO": "LIRF",
        "MAD": "LEMD", "BCN": "LEBL",
        "ZRH": "LSZH",
        "IST": "LTFM",
        "DXB": "OMDB", "AUH": "OMAA", "DOH": "OTHH",
        "NRT": "RJAA", "HND": "RJTT",
        "ICN": "RKSI",
        "SIN": "WSSS",
        "HKG": "VHHH",
        "PVG": "ZSPD", "PEK": "ZBAA",
        "TPE": "RCTP",
        "BKK": "VTBS",
        "DEL": "VIDP", "BOM": "VABB",
        "SYD": "YSSY", "MEL": "YMML",
        "AKL": "NZAA",
        "GRU": "SBGR", "EZE": "SAEZ", "SCL": "SCEL",
        "LIM": "SPJC", "BOG": "SKBO", "PTY": "MPTO",
        "JNB": "FAOR",
    ]

    private func toICAO(_ code: String) -> String {
        let c = code.uppercased().trimmingCharacters(in: .whitespaces)
        if c.count == 4 { return c }
        if let icao = Self.iataToICAO[c] { return icao }
        if c.count == 3 { return "K\(c)" }
        return c
    }
}
