import SwiftUI

struct ForecastResultView: View {
    let forecast: FlightForecast
    let isPilotMode: Bool
    let profile: PassengerProfile
    let flightService: FlightService
    @Environment(\.colorScheme) private var colorScheme
    @State private var appeared = false
    @State private var scoreAnimated = false
    @State private var expandedSection: String?

    var body: some View {
        VStack(spacing: 16) {
            FlightStatusCard(forecast: forecast)

            scoreHero

            conditionsRow

            RouteMapCard(forecast: forecast)

            RegionalTurbulenceView(
                insights: forecast.regionalInsights,
                departureCode: forecast.departureAirport.code,
                arrivalCode: forecast.arrivalAirport.code
            )

            FlightShareButton(forecast: forecast)

            TurbulenceTimelineView(forecast: forecast)

            WhatThisMeansView(forecast: forecast, profile: profile)

            PilotInsightView(forecast: forecast)

            weatherSummary

            BestSeatView(forecast: forecast)

            CompareFlightsView(currentForecast: forecast, flightService: flightService)

            if isPilotMode {
                pilotModeSection
            }

            reassuranceSection
            educationSection
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 20)
        .onAppear {
            withAnimation(.spring(response: 0.5).delay(0.1)) { appeared = true }
            withAnimation(.easeOut(duration: 1.0).delay(0.5)) { scoreAnimated = true }
        }
    }

    private var scoreHero: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(forecast.flightNumber)
                        .font(.title3.weight(.bold))
                    HStack(spacing: 6) {
                        Text(forecast.departureAirport.code)
                            .font(.subheadline.weight(.semibold))
                        Image(systemName: "arrow.right")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                        Text(forecast.arrivalAirport.code)
                            .font(.subheadline.weight(.semibold))
                    }
                    .foregroundStyle(.secondary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text(forecast.durationFormatted)
                        .font(.subheadline.weight(.medium))
                    Text(forecast.departureTime, style: .date)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            HStack(spacing: 24) {
                ZStack {
                    Circle()
                        .stroke(Color(.systemGray5), lineWidth: 6)
                        .frame(width: 90, height: 90)

                    Circle()
                        .trim(from: 0, to: scoreAnimated ? CGFloat(forecast.overallScore) / 10.0 : 0)
                        .stroke(
                            TurbyTurbulenceForecastTheme.scoreGradient(for: forecast.overallScore),
                            style: StrokeStyle(lineWidth: 6, lineCap: .round)
                        )
                        .frame(width: 90, height: 90)
                        .rotationEffect(.degrees(-90))

                    VStack(spacing: 0) {
                        Text("\(forecast.overallScore)")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundStyle(TurbyTurbulenceForecastTheme.scoreColor(for: forecast.overallScore))
                        Text("/10")
                            .font(.caption2.weight(.medium))
                            .foregroundStyle(.secondary)
                    }
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text(forecast.overallLevel.label)
                        .font(.title3.weight(.bold))
                        .foregroundStyle(TurbyTurbulenceForecastTheme.scoreColor(for: forecast.overallScore))
                    Text(forecast.summaryText(for: profile))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding(18)
        .glassCard()
    }

    private var conditionsRow: some View {
        HStack(spacing: 10) {
            ConditionCard(phase: "Takeoff", level: forecast.takeoffCondition, icon: "airplane.departure")
            ConditionCard(phase: "Cruise", level: forecast.cruiseCondition, icon: "airplane")
            ConditionCard(phase: "Landing", level: forecast.landingCondition, icon: "airplane.arrival")
        }
    }

    private var weatherSummary: some View {
        VStack(spacing: 14) {
            HStack {
                Image(systemName: "cloud.sun.fill")
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(TurbyTurbulenceForecastTheme.accent)
                Text("Weather Summary")
                    .font(.headline)
                Spacer()
            }

            HStack(spacing: 12) {
                WeatherInfoPill(
                    icon: "airplane.departure",
                    label: forecast.departureAirport.code,
                    value: forecast.takeoffWeather.cloudDescription,
                    detail: forecast.takeoffWeather.windDescription
                )
                WeatherInfoPill(
                    icon: "airplane.arrival",
                    label: forecast.arrivalAirport.code,
                    value: forecast.landingWeather.cloudDescription,
                    detail: forecast.landingWeather.windDescription
                )
            }
        }
        .padding(18)
        .glassCard()
    }

    private var pilotModeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "gauge.with.dots.needle.33percent")
                    .foregroundStyle(.orange)
                Text("Pilot Mode")
                    .font(.headline)
                Spacer()
                Text("RAW DATA")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.orange)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(.orange.opacity(0.12)))
            }

            if let metar = forecast.metar {
                VStack(alignment: .leading, spacing: 4) {
                    Text("METAR")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.secondary)
                    Text(metar)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(.primary)
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(RoundedRectangle(cornerRadius: 10).fill(Color(.systemGray6).opacity(colorScheme == .dark ? 0.3 : 1)))
            }

            if let taf = forecast.taf {
                VStack(alignment: .leading, spacing: 4) {
                    Text("TAF")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.secondary)
                    Text(taf)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(.primary)
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(RoundedRectangle(cornerRadius: 10).fill(Color(.systemGray6).opacity(colorScheme == .dark ? 0.3 : 1)))
            }

            HStack(spacing: 0) {
                PilotDataPoint(label: "Wind", value: "\(Int(forecast.takeoffWeather.windSpeed)) kt", icon: "wind")
                PilotDataPoint(label: "Vis", value: "\(Int(forecast.takeoffWeather.visibility)) SM", icon: "eye")
                PilotDataPoint(label: "Press", value: "\(String(format: "%.0f", forecast.takeoffWeather.pressure)) hPa", icon: "gauge.with.dots.needle.bottom.50percent")
                PilotDataPoint(label: "RH", value: "\(forecast.takeoffWeather.humidity)%", icon: "humidity")
            }
        }
        .padding(18)
        .glassCard()
    }

    private var reassuranceSection: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "heart.fill")
                    .foregroundStyle(.pink)
                Text("You're safe")
                    .font(.headline)
                Spacer()
            }

            Text(forecast.overallLevel.reassurance)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(TurbyTurbulenceForecastTheme.turbulenceColor(for: .smooth))
                Text("Modern aircraft are built to handle turbulence far beyond what passengers ever experience.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(TurbyTurbulenceForecastTheme.turbulenceColor(for: .smooth).opacity(0.06))
            )
        }
        .padding(18)
        .glassCard()
    }

    private var educationSection: some View {
        VStack(spacing: 10) {
            ExpandableInfoCard(
                title: "Why does turbulence happen?",
                icon: "questionmark.circle.fill",
                iconColor: TurbyTurbulenceForecastTheme.accent,
                content: "Turbulence is caused by changes in air currents - from jet streams, mountains, or weather fronts. It's like waves in the ocean. Your plane rides through them smoothly, just like a boat rides over waves.",
                isExpanded: expandedSection == "why",
                toggle: { withAnimation(.snappy) { expandedSection = expandedSection == "why" ? nil : "why" } }
            )
            ExpandableInfoCard(
                title: "Is turbulence dangerous?",
                icon: "shield.checkered",
                iconColor: TurbyTurbulenceForecastTheme.turbulenceColor(for: .smooth),
                content: "No. Turbulence has never caused a modern aircraft to crash. Planes are engineered to withstand forces far greater than any turbulence. The biggest risk is not wearing your seatbelt - so keep it fastened when seated.",
                isExpanded: expandedSection == "danger",
                toggle: { withAnimation(.snappy) { expandedSection = expandedSection == "danger" ? nil : "danger" } }
            )
            ExpandableInfoCard(
                title: "What do pilots do?",
                icon: "person.fill",
                iconColor: .orange,
                content: "Pilots receive real-time weather reports, communicate with other aircraft, and will always try to adjust altitude or route to find smoother air. They're trained extensively for all conditions and are always in control.",
                isExpanded: expandedSection == "pilots",
                toggle: { withAnimation(.snappy) { expandedSection = expandedSection == "pilots" ? nil : "pilots" } }
            )
        }
    }
}

struct ConditionCard: View {
    let phase: String
    let level: TurbulenceLevel
    var icon: String = ""
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(TurbyTurbulenceForecastTheme.turbulenceColor(for: level).opacity(0.12))
                    .frame(width: 40, height: 40)
                Image(systemName: level.icon)
                    .font(.body)
                    .foregroundStyle(TurbyTurbulenceForecastTheme.turbulenceColor(for: level))
            }

            Text(phase)
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(level.label)
                .font(.caption.weight(.bold))
                .foregroundStyle(TurbyTurbulenceForecastTheme.turbulenceColor(for: level))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .glassCard()
    }
}

struct WeatherInfoPill: View {
    let icon: String
    let label: String
    let value: String
    let detail: String
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(label)
                    .font(.caption.weight(.bold))
            }
            Text(value)
                .font(.subheadline.weight(.medium))
            Text(detail)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6).opacity(colorScheme == .dark ? 0.3 : 1))
        )
    }
}

struct PilotDataPoint: View {
    let label: String
    let value: String
    var icon: String = ""

    var body: some View {
        VStack(spacing: 4) {
            if !icon.isEmpty {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Text(value)
                .font(.system(.caption, design: .monospaced, weight: .bold))
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct ExpandableInfoCard: View {
    let title: String
    let icon: String
    let iconColor: Color
    let content: String
    let isExpanded: Bool
    let toggle: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button(action: toggle) {
                HStack(spacing: 10) {
                    Image(systemName: icon)
                        .foregroundStyle(iconColor)
                    Text(title)
                        .font(.subheadline.weight(.medium))
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                }
                .foregroundStyle(.primary)
            }

            if isExpanded {
                Text(content)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 12)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(16)
        .glassCard()
    }
}
