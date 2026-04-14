import SwiftUI
import StoreKit

struct HomeView: View {
    let viewModel: AppViewModel
    @Environment(\.requestReview) private var requestReview
    @Environment(\.colorScheme) private var colorScheme
    @State private var appeared = false

    var body: some View {
        NavigationStack {
            ZStack {
                TurbyTurbulenceForecastTheme.calmBackground(for: colorScheme)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        headerSection

                        searchCard

                        if viewModel.flightService.isLoading {
                            ShimmerLoadingView()
                                .transition(.opacity.combined(with: .scale(scale: 0.97)))
                        }

                        if let forecast = viewModel.currentForecast, viewModel.subscriptionService.isSubscribed {
                            FlightCountdownView(departureTime: forecast.departureTime, flightStatus: forecast.flightStatus)
                                .transition(.asymmetric(insertion: .scale(scale: 0.95).combined(with: .opacity), removal: .opacity))
                            ForecastResultView(
                                forecast: forecast,
                                isPilotMode: viewModel.isPilotMode,
                                profile: viewModel.passengerProfile,
                                flightService: viewModel.flightService
                            )
                            .transition(.asymmetric(insertion: .move(edge: .bottom).combined(with: .opacity), removal: .opacity))

                            if let timestamp = viewModel.forecastTimestamp {
                                forecastTimestampView(timestamp)
                            }
                        } else if viewModel.currentForecast != nil && !viewModel.subscriptionService.isSubscribed {
                            lockedResultCard
                        }

                        if viewModel.currentForecast == nil && !viewModel.flightService.isLoading {
                            if !viewModel.historyService.entries.isEmpty {
                                recentFlightsSection
                            }

                            quickTipsSection

                            turbulenceFactCard
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 100)
                    .animation(.spring(response: 0.5, dampingFraction: 0.85), value: viewModel.currentForecast?.id)
                    .animation(.spring(response: 0.4), value: viewModel.flightService.isLoading)
                }
                .scrollIndicators(.hidden)

                ConfettiView(isActive: Binding(
                    get: { viewModel.showConfetti },
                    set: { viewModel.showConfetti = $0 }
                ))
                .ignoresSafeArea()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    TurbyTurbulenceForecastLogo(style: .compact)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Toggle(isOn: Binding(
                            get: { viewModel.isPilotMode },
                            set: { viewModel.isPilotMode = $0 }
                        )) {
                            Label("Pilot Mode", systemImage: "gauge.with.dots.needle.33percent")
                        }

                        Menu("Passenger Profile") {
                            ForEach(PassengerProfile.allCases, id: \.self) { profile in
                                Button {
                                    viewModel.passengerProfile = profile
                                } label: {
                                    Label(profile.title, systemImage: profile.icon)
                                }
                            }
                        }

                        Button {
                            Task { await viewModel.notificationService.requestPermission() }
                        } label: {
                            Label("Enable Notifications", systemImage: "bell.badge")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .font(.body.weight(.medium))
                    }
                }
            }
            .fullScreenCover(isPresented: Binding(
                get: { viewModel.showPaywall },
                set: { viewModel.showPaywall = $0 }
            )) {
                ZStack {
                    PaywallView(viewModel: viewModel)
                    if viewModel.showExitIntent {
                        ExitIntentView(viewModel: viewModel)
                    }
                }
            }
            .sheet(isPresented: Binding(
                get: { viewModel.showFlightPicker },
                set: { viewModel.showFlightPicker = $0 }
            )) {
                FlightPickerSheet(
                    flights: viewModel.availableFlights,
                    departureCode: viewModel.searchQuery.departureAirport.isEmpty ? (viewModel.homeAirport?.iata ?? "???") : viewModel.searchQuery.departureAirport.uppercased(),
                    searchDate: viewModel.searchQuery.date
                ) { flight in
                    Task { await viewModel.selectFlight(flight) }
                }
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
            }
        }
        .sensoryFeedback(.success, trigger: viewModel.currentForecast?.id)
        .opacity(appeared ? 1 : 0)
        .onAppear { withAnimation(.easeIn(duration: 0.3)) { appeared = true } }
        .task {
            if viewModel.isOnboardingPaywall && !viewModel.showPaywall && !viewModel.subscriptionService.isSubscribed {
                try? await Task.sleep(for: .milliseconds(600))
                viewModel.showPaywall = true
            }
        }
        .onChange(of: viewModel.shouldRequestReview) { _, newValue in
            if newValue {
                viewModel.shouldRequestReview = false
                requestReview()
            }
        }
    }

    private func forecastTimestampView(_ timestamp: Date) -> some View {
        HStack(spacing: 6) {
            Image(systemName: "clock")
                .font(.caption2)
                .foregroundStyle(.tertiary)
            Text("Updated \(timestamp, format: .relative(presentation: .named))")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
    }

    private var headerSection: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 6) {
                Text(greeting)
                    .font(.title2.weight(.bold))
                HStack(spacing: 6) {
                    Image(systemName: viewModel.passengerProfile.icon)
                        .font(.caption)
                        .foregroundStyle(TurbyTurbulenceForecastTheme.accent)
                    Text(viewModel.passengerProfile.title)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            if viewModel.subscriptionService.isSubscribed {
                Text("PRO")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [TurbyTurbulenceForecastTheme.accent, TurbyTurbulenceForecastTheme.accentLight],
                                    startPoint: .leading, endPoint: .trailing
                                )
                            )
                    )
            }
        }
        .padding(.top, 8)
    }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        let timeGreeting: String
        switch hour {
        case 5..<12: timeGreeting = "Good morning"
        case 12..<17: timeGreeting = "Good afternoon"
        default: timeGreeting = "Good evening"
        }
        let name = viewModel.firstName.trimmingCharacters(in: .whitespaces)
        if name.isEmpty {
            return timeGreeting
        }
        return "\(timeGreeting), \(name)"
    }

    private var searchCard: some View {
        VStack(spacing: 14) {
            HStack(spacing: 0) {
                SearchSegment(
                    title: "Flight #",
                    icon: "number",
                    isSelected: viewModel.searchQuery.searchByFlightNumber
                ) {
                    withAnimation(.snappy) { viewModel.searchQuery.searchByFlightNumber = true }
                }
                SearchSegment(
                    title: "Route",
                    icon: "airplane",
                    isSelected: !viewModel.searchQuery.searchByFlightNumber
                ) {
                    withAnimation(.snappy) { viewModel.searchQuery.searchByFlightNumber = false }
                }
            }
            .padding(3)
            .background(Color(.systemGray6).opacity(colorScheme == .dark ? 0.3 : 1), in: Capsule())

            if viewModel.searchQuery.searchByFlightNumber {
                FlightAutocompleteField(
                    placeholder: viewModel.favoriteAirline != nil ? "e.g. \(viewModel.favoriteAirline!.iata)1234" : "Flight number (e.g. AA1234)",
                    text: Binding(
                        get: { viewModel.searchQuery.flightNumber },
                        set: {
                            viewModel.searchQuery.flightNumber = $0
                            viewModel.preselectedFlight = nil
                            viewModel.flightService.updateAutocomplete(for: $0, date: viewModel.searchQuery.date)
                        }
                    ),
                    suggestions: viewModel.flightService.autocompleteSuggestions,
                    isLoading: viewModel.flightService.isLoadingAutocomplete,
                    onSelect: { suggestion in
                        viewModel.selectFlightFromAutocomplete(suggestion)
                    }
                )
            } else {
                AirportAutocompleteField(
                    placeholder: viewModel.homeAirport != nil ? "From (\(viewModel.homeAirport!.iata))" : "From (e.g. JFK)",
                    text: Binding(
                        get: { viewModel.searchQuery.departureAirport },
                        set: { viewModel.searchQuery.departureAirport = $0 }
                    ),
                    icon: "airplane.departure",
                    onAirportSelected: { airport in
                        viewModel.searchQuery.departureAirport = airport.iata
                    }
                )
                AirportAutocompleteField(
                    placeholder: "To (e.g. LAX)",
                    text: Binding(
                        get: { viewModel.searchQuery.arrivalAirport },
                        set: { viewModel.searchQuery.arrivalAirport = $0 }
                    ),
                    icon: "airplane.arrival",
                    onAirportSelected: { airport in
                        viewModel.searchQuery.arrivalAirport = airport.iata
                    }
                )
            }

            DatePicker(
                "Date",
                selection: Binding(
                    get: { viewModel.searchQuery.date },
                    set: { viewModel.searchQuery.date = $0 }
                ),
                displayedComponents: [.date]
            )
            .datePickerStyle(.compact)

            if let error = viewModel.flightService.errorMessage {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.orange.opacity(0.08))
                )
            }

            Button {
                Task { await viewModel.searchFlight() }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "sparkle.magnifyingglass")
                    Text("Get Forecast")
                }
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(
                            LinearGradient(
                                colors: [TurbyTurbulenceForecastTheme.accent, TurbyTurbulenceForecastTheme.accentLight],
                                startPoint: .leading, endPoint: .trailing
                            )
                        )
                        .shadow(color: TurbyTurbulenceForecastTheme.accent.opacity(0.3), radius: 8, y: 4)
                )
            }
            .sensoryFeedback(.impact(weight: .medium), trigger: viewModel.flightService.isLoading)
        }
        .padding(18)
        .glassCard()
    }

    private var lockedResultCard: some View {
        VStack(spacing: 18) {
            ZStack {
                Circle()
                    .fill(TurbyTurbulenceForecastTheme.accent.opacity(0.1))
                    .frame(width: 72, height: 72)
                Image(systemName: "lock.fill")
                    .font(.title)
                    .foregroundStyle(TurbyTurbulenceForecastTheme.accent)
            }
            Text("Your forecast is ready!")
                .font(.title3.weight(.bold))
            Text("Subscribe to unlock your full turbulence\nreport, seat tips, and more")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button {
                viewModel.showPaywall = true
            } label: {
                Text("Unlock Forecast")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 13)
                    .background(
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [TurbyTurbulenceForecastTheme.accent, TurbyTurbulenceForecastTheme.accentLight],
                                    startPoint: .leading, endPoint: .trailing
                                )
                            )
                            .shadow(color: TurbyTurbulenceForecastTheme.accent.opacity(0.3), radius: 8, y: 4)
                    )
            }
        }
        .frame(maxWidth: .infinity)
        .padding(28)
        .glassCard()
    }

    private var recentFlightsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "clock.arrow.circlepath")
                    .foregroundStyle(TurbyTurbulenceForecastTheme.accent)
                Text("Recent Searches")
                    .font(.headline)
                Spacer()
            }

            ForEach(viewModel.historyService.entries.prefix(3)) { entry in
                Button {
                    viewModel.searchQuery.flightNumber = entry.flightNumber
                    viewModel.searchQuery.searchByFlightNumber = true
                    viewModel.searchQuery.date = Date()
                    Task { await viewModel.searchFlight() }
                } label: {
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(TurbyTurbulenceForecastTheme.scoreColor(for: entry.overallScore).opacity(0.12))
                                .frame(width: 40, height: 40)
                            Text("\(entry.overallScore)")
                                .font(.subheadline.weight(.bold))
                                .foregroundStyle(TurbyTurbulenceForecastTheme.scoreColor(for: entry.overallScore))
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text(entry.flightNumber)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.primary)
                            HStack(spacing: 4) {
                                Text(entry.departureCode)
                                Image(systemName: "arrow.right")
                                    .font(.caption2)
                                Text(entry.arrivalCode)
                            }
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Image(systemName: "arrow.clockwise")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.systemGray6).opacity(colorScheme == .dark ? 0.3 : 1))
                    )
                }
            }
        }
        .padding(18)
        .glassCard()
    }

    private var quickTipsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "sparkles")
                    .foregroundStyle(.yellow)
                Text("Flight Tips")
                    .font(.headline)
                Spacer()
            }

            VStack(spacing: 8) {
                TipRow(icon: "clock.fill", color: TurbyTurbulenceForecastTheme.accent, text: "Check closer to departure for the most accurate forecast")
                TipRow(icon: "chair.lounge.fill", color: .orange, text: "Seats over the wings feel the least turbulence")
                TipRow(icon: "seatbelt", color: TurbyTurbulenceForecastTheme.turbulenceColor(for: .smooth), text: "Keep your seatbelt fastened when seated — even in smooth air")
            }
        }
        .padding(18)
        .glassCard()
    }

    private var turbulenceFactCard: some View {
        VStack(spacing: 14) {
            HStack {
                Image(systemName: "brain.head.profile.fill")
                    .foregroundStyle(TurbyTurbulenceForecastTheme.accent)
                Text("Did You Know?")
                    .font(.headline)
                Spacer()
            }

            Text(turbulenceFact)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 6) {
                Image(systemName: "shield.checkered")
                    .font(.caption)
                    .foregroundStyle(TurbyTurbulenceForecastTheme.turbulenceColor(for: .smooth))
                Text("Turbulence has never caused a modern aircraft to crash.")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(18)
        .glassCard()
    }

    private var turbulenceFact: String {
        let facts = [
            "Commercial aircraft are tested to withstand 1.5x more force than the most extreme turbulence ever recorded. You're in an incredibly strong machine.",
            "Pilots use weather radar, reports from other aircraft, and satellite data to navigate around turbulence — they're always planning the smoothest path.",
            "Morning flights tend to have less turbulence because the sun hasn't heated the ground enough to create thermal updrafts yet.",
            "Turbulence feels worse than it actually is. What feels like a huge drop is usually less than 20 feet — barely noticeable from outside the plane.",
            "The busiest air route in the world (Jeju–Seoul) experiences turbulence regularly, yet has a perfect safety record with millions of flights."
        ]
        let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 0
        return facts[dayOfYear % facts.count]
    }
}

struct SearchSegment: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption)
                Text(title)
                    .font(.subheadline.weight(.medium))
            }
            .foregroundStyle(isSelected ? .primary : .secondary)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity)
            .background(
                Capsule()
                    .fill(isSelected ? Color(.systemBackground) : .clear)
                    .shadow(color: isSelected ? .black.opacity(0.06) : .clear, radius: 4, y: 2)
            )
        }
        .sensoryFeedback(.selection, trigger: isSelected)
    }
}

struct TipRow: View {
    let icon: String
    let color: Color
    let text: String
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.12))
                    .frame(width: 32, height: 32)
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundStyle(color)
            }
            Text(text)
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(.systemGray6).opacity(colorScheme == .dark ? 0.3 : 1))
        )
    }
}

struct SearchField: View {
    let placeholder: String
    @Binding var text: String
    let icon: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .foregroundStyle(.secondary)
                .frame(width: 20)
            TextField(placeholder, text: $text)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.characters)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
    }
}
