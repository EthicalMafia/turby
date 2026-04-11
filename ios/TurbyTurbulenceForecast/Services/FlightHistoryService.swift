import Foundation

@Observable
@MainActor
class FlightHistoryService {
    var entries: [FlightHistoryEntry] = []

    private let storageKey = "flightHistory"

    init() {
        loadHistory()
    }

    func addEntry(_ forecast: FlightForecast) {
        let entry = FlightHistoryEntry(forecast: forecast)
        entries.removeAll { $0.flightNumber == entry.flightNumber && Calendar.current.isDate($0.date, inSameDayAs: entry.date) }
        entries.insert(entry, at: 0)
        if entries.count > 50 {
            entries = Array(entries.prefix(50))
        }
        saveHistory()
    }

    func deleteEntry(_ entry: FlightHistoryEntry) {
        entries.removeAll { $0.id == entry.id }
        saveHistory()
    }

    func clearAll() {
        entries.removeAll()
        saveHistory()
    }

    private func loadHistory() {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let decoded = try? JSONDecoder().decode([FlightHistoryEntry].self, from: data) else { return }
        entries = decoded
    }

    private func saveHistory() {
        guard let data = try? JSONEncoder().encode(entries) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
    }
}
