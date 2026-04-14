import SwiftUI

struct OnboardingInputPage: View {
    let viewModel: AppViewModel
    @Binding var currentPage: Int
    @State private var appeared = false

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "magnifyingglass")
                .font(.system(size: 48, weight: .light))
                .foregroundStyle(.white)

            VStack(spacing: 8) {
                Text("Find your flight")
                    .font(.system(.title2, design: .default, weight: .bold))
                    .foregroundStyle(.white)

                Text("Enter your flight number or route\nto get your personalized forecast")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
            }

            VStack(spacing: 16) {
                HStack(spacing: 0) {
                    SegmentButton(
                        title: "Flight Number",
                        isSelected: viewModel.searchQuery.searchByFlightNumber
                    ) {
                        viewModel.searchQuery.searchByFlightNumber = true
                    }
                    SegmentButton(
                        title: "Airports",
                        isSelected: !viewModel.searchQuery.searchByFlightNumber
                    ) {
                        viewModel.searchQuery.searchByFlightNumber = false
                    }
                }
                .background(
                    Capsule().fill(.white.opacity(0.1))
                )

                if viewModel.searchQuery.searchByFlightNumber {
                    OnboardingFlightAutocompleteField(
                        placeholder: "e.g. AA1234",
                        text: Binding(
                            get: { viewModel.searchQuery.flightNumber },
                            set: {
                                viewModel.searchQuery.flightNumber = $0
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
                    OnboardingTextField(
                        placeholder: "From (e.g. JFK)",
                        text: Binding(
                            get: { viewModel.searchQuery.departureAirport },
                            set: { viewModel.searchQuery.departureAirport = $0 }
                        ),
                        icon: "airplane.departure"
                    )
                    OnboardingTextField(
                        placeholder: "To (e.g. LAX)",
                        text: Binding(
                            get: { viewModel.searchQuery.arrivalAirport },
                            set: { viewModel.searchQuery.arrivalAirport = $0 }
                        ),
                        icon: "airplane.arrival"
                    )
                }

                DatePicker(
                    "Flight Date",
                    selection: Binding(
                        get: { viewModel.searchQuery.date },
                        set: { viewModel.searchQuery.date = $0 }
                    ),
                    displayedComponents: [.date]
                )
                .datePickerStyle(.compact)
                .tint(.white)
                .foregroundStyle(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(.white.opacity(0.12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .strokeBorder(.white.opacity(0.2), lineWidth: 1)
                        )
                )
            }

            if let error = viewModel.flightService.errorMessage {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.8))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(.white.opacity(0.1))
                )
            }

            Button {
                Task {
                    await viewModel.searchFlight()
                    if viewModel.currentForecast != nil {
                        viewModel.isOnboardingPaywall = true
                        viewModel.showPaywall = false
                        viewModel.completeOnboarding()
                    }
                }
            } label: {
                HStack(spacing: 8) {
                    if viewModel.flightService.isLoading {
                        ProgressView()
                            .tint(.blue)
                        Text("Searching...")
                    } else {
                        Image(systemName: "sparkle.magnifyingglass")
                        Text("Get My Forecast")
                    }
                }
                .font(.headline)
                .foregroundStyle(.blue)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.white)
                )
                .animation(.easeInOut(duration: 0.2), value: viewModel.flightService.isLoading)
            }
            .disabled(!isInputValid || viewModel.flightService.isLoading)
            .opacity(isInputValid && !viewModel.flightService.isLoading ? 1 : 0.6)

            Spacer()
        }
        .padding(.horizontal, 24)
        .opacity(appeared ? 1 : 0)
        .onAppear {
            withAnimation(.easeIn(duration: 0.4)) { appeared = true }
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
                Task {
                    await viewModel.selectFlight(flight)
                    viewModel.isOnboardingPaywall = true
                    viewModel.showPaywall = false
                    viewModel.completeOnboarding()
                }
            }
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
    }

    private var isInputValid: Bool {
        if viewModel.searchQuery.searchByFlightNumber {
            return !viewModel.searchQuery.flightNumber.trimmingCharacters(in: .whitespaces).isEmpty
        }
        return !viewModel.searchQuery.departureAirport.trimmingCharacters(in: .whitespaces).isEmpty &&
               !viewModel.searchQuery.arrivalAirport.trimmingCharacters(in: .whitespaces).isEmpty
    }
}

struct SegmentButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.white)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity)
                .background(
                    Capsule()
                        .fill(isSelected ? .white.opacity(0.25) : .clear)
                )
        }
    }
}

struct OnboardingTextField: View {
    let placeholder: String
    @Binding var text: String
    let icon: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(.white.opacity(0.6))
                .frame(width: 24)

            TextField("", text: $text, prompt: Text(placeholder).foregroundStyle(.white.opacity(0.5)))
                .foregroundStyle(.white)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.characters)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(.white.opacity(0.12))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .strokeBorder(.white.opacity(0.2), lineWidth: 1)
                )
        )
    }
}
