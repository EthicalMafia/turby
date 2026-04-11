import WidgetKit
import SwiftUI

nonisolated struct WidgetForecastData: Codable, Sendable {
    let flightNumber: String
    let departureCode: String
    let arrivalCode: String
    let overallScore: Int
    let departureTime: Date
    let updatedAt: Date
}

nonisolated struct TurbyEntry: TimelineEntry {
    let date: Date
    let forecast: WidgetForecastData?
}

nonisolated struct TurbyProvider: TimelineProvider {
    func placeholder(in context: Context) -> TurbyEntry {
        TurbyEntry(date: .now, forecast: WidgetForecastData(
            flightNumber: "AA1234",
            departureCode: "JFK",
            arrivalCode: "LAX",
            overallScore: 2,
            departureTime: Date().addingTimeInterval(3600 * 5),
            updatedAt: Date()
        ))
    }

    func getSnapshot(in context: Context, completion: @escaping (TurbyEntry) -> Void) {
        completion(TurbyEntry(date: .now, forecast: loadForecast()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TurbyEntry>) -> Void) {
        let entry = TurbyEntry(date: .now, forecast: loadForecast())
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 30, to: Date())!
        completion(Timeline(entries: [entry], policy: .after(nextUpdate)))
    }

    private func loadForecast() -> WidgetForecastData? {
        guard let defaults = UserDefaults(suiteName: "group.app.rork.turby"),
              let data = defaults.data(forKey: "widgetForecast") else { return nil }
        return try? JSONDecoder().decode(WidgetForecastData.self, from: data)
    }
}

struct TurbyWidgetSmallView: View {
    let entry: TurbyEntry

    var body: some View {
        if let forecast = entry.forecast {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    Image(systemName: "airplane")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.white.opacity(0.7))
                    Text(forecast.flightNumber)
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(.white)
                }

                HStack(spacing: 4) {
                    Text(forecast.departureCode)
                        .font(.caption2.weight(.medium))
                    Image(systemName: "arrow.right")
                        .font(.system(size: 8))
                    Text(forecast.arrivalCode)
                        .font(.caption2.weight(.medium))
                }
                .foregroundStyle(.white.opacity(0.7))

                Spacer()

                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text("\(forecast.overallScore)")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    Text("/10")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.6))
                }

                Text(levelLabel(for: forecast.overallScore))
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.85))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .containerBackground(for: .widget) {
                backgroundGradient(for: forecast.overallScore)
            }
        } else {
            VStack(spacing: 8) {
                Image(systemName: "cloud.sun.fill")
                    .font(.title2)
                    .foregroundStyle(.white.opacity(0.8))
                Text("No Forecast")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.white.opacity(0.7))
                Text("Search a flight\nin Turby")
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.5))
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .containerBackground(for: .widget) {
                LinearGradient(
                    colors: [Color(red: 0.42, green: 0.68, blue: 0.92), Color(red: 0.22, green: 0.45, blue: 0.78)],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                )
            }
        }
    }
}

struct TurbyWidgetMediumView: View {
    let entry: TurbyEntry

    var body: some View {
        if let forecast = entry.forecast {
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 6) {
                        Image(systemName: "airplane")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(.white.opacity(0.7))
                        Text(forecast.flightNumber)
                            .font(.headline)
                            .foregroundStyle(.white)
                    }

                    HStack(spacing: 6) {
                        Text(forecast.departureCode)
                            .font(.caption.weight(.semibold))
                        Image(systemName: "arrow.right")
                            .font(.system(size: 9))
                        Text(forecast.arrivalCode)
                            .font(.caption.weight(.semibold))
                    }
                    .foregroundStyle(.white.opacity(0.7))

                    Spacer()

                    Text(forecast.departureTime, style: .relative)
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.6))
                }

                Spacer()

                VStack(spacing: 4) {
                    ZStack {
                        Circle()
                            .strokeBorder(.white.opacity(0.2), lineWidth: 3)
                            .frame(width: 64, height: 64)
                        Circle()
                            .trim(from: 0, to: CGFloat(forecast.overallScore) / 10.0)
                            .stroke(.white, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                            .frame(width: 64, height: 64)
                            .rotationEffect(.degrees(-90))

                        Text("\(forecast.overallScore)")
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                    }

                    Text(levelLabel(for: forecast.overallScore))
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.85))
                }
            }
            .containerBackground(for: .widget) {
                backgroundGradient(for: forecast.overallScore)
            }
        } else {
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 6) {
                        Image(systemName: "airplane")
                            .font(.caption.weight(.bold))
                        Text("turby")
                            .font(.headline)
                    }
                    .foregroundStyle(.white)

                    Text("Search a flight to see\nyour turbulence forecast")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.6))
                }

                Spacer()

                Image(systemName: "cloud.sun.fill")
                    .font(.largeTitle)
                    .foregroundStyle(.white.opacity(0.3))
            }
            .containerBackground(for: .widget) {
                LinearGradient(
                    colors: [Color(red: 0.42, green: 0.68, blue: 0.92), Color(red: 0.22, green: 0.45, blue: 0.78)],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                )
            }
        }
    }
}

struct TurbyWidgetView: View {
    @Environment(\.widgetFamily) var family
    var entry: TurbyEntry

    var body: some View {
        switch family {
        case .systemSmall:
            TurbyWidgetSmallView(entry: entry)
        default:
            TurbyWidgetMediumView(entry: entry)
        }
    }
}

struct TurbyWidget: Widget {
    let kind: String = "TurbyWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TurbyProvider()) { entry in
            TurbyWidgetView(entry: entry)
        }
        .configurationDisplayName("Flight Forecast")
        .description("See your latest turbulence forecast at a glance.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

private func levelLabel(for score: Int) -> String {
    switch score {
    case 0...2: "Smooth"
    case 3...4: "Light bumps"
    case 5...7: "Bumpy"
    default: "Very bumpy"
    }
}

private func backgroundGradient(for score: Int) -> some View {
    let colors: [Color]
    switch score {
    case 0...2:
        colors = [Color(red: 0.2, green: 0.65, blue: 0.5), Color(red: 0.15, green: 0.5, blue: 0.4)]
    case 3...4:
        colors = [Color(red: 0.42, green: 0.68, blue: 0.92), Color(red: 0.22, green: 0.45, blue: 0.78)]
    case 5...7:
        colors = [Color(red: 0.9, green: 0.55, blue: 0.2), Color(red: 0.75, green: 0.4, blue: 0.15)]
    default:
        colors = [Color(red: 0.85, green: 0.3, blue: 0.3), Color(red: 0.65, green: 0.2, blue: 0.2)]
    }
    return LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
}
