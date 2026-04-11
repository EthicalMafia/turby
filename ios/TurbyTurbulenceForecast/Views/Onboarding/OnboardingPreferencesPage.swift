import SwiftUI

struct OnboardingPreferencesPage: View {
    let viewModel: AppViewModel
    @Binding var currentPage: Int
    @State private var appeared = false
    @State private var showAirportPicker = false
    @State private var showAirlinePicker = false

    var body: some View {
        VStack(spacing: 28) {
            Spacer()

            VStack(spacing: 12) {
                Image(systemName: "star.circle.fill")
                    .font(.system(size: 52, weight: .light))
                    .foregroundStyle(.white)
                    .symbolEffect(.pulse, options: .repeating)

                Text(viewModel.firstName.isEmpty ? "Your preferences" : "Nice to meet you, \(viewModel.firstName)!")
                    .font(.system(.title, design: .default, weight: .bold))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)

                Text("Set your home airport and favorite airline\nfor a faster experience")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.75))
                    .multilineTextAlignment(.center)
            }

            VStack(spacing: 12) {
                Button { showAirportPicker = true } label: {
                    HStack(spacing: 14) {
                        Image(systemName: "building.2.fill")
                            .font(.title3)
                            .foregroundStyle(.white)
                            .frame(width: 44, height: 44)
                            .background(
                                Circle()
                                    .fill(.white.opacity(viewModel.homeAirport != nil ? 0.25 : 0.1))
                            )

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Home Airport")
                                .font(.headline)
                                .foregroundStyle(.white)
                            if let airport = viewModel.homeAirport {
                                Text("\(airport.iata) — \(airport.name)")
                                    .font(.caption)
                                    .foregroundStyle(.white.opacity(0.7))
                                    .lineLimit(1)
                            } else {
                                Text("Tap to select")
                                    .font(.caption)
                                    .foregroundStyle(.white.opacity(0.5))
                            }
                        }

                        Spacer()

                        if viewModel.homeAirport != nil {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.title3)
                                .foregroundStyle(.white)
                                .transition(.scale.combined(with: .opacity))
                        } else {
                            Image(systemName: "chevron.right")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.white.opacity(0.5))
                        }
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(viewModel.homeAirport != nil ? .white.opacity(0.2) : .white.opacity(0.08))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .strokeBorder(viewModel.homeAirport != nil ? .white.opacity(0.5) : .white.opacity(0.12), lineWidth: viewModel.homeAirport != nil ? 2 : 1)
                            )
                    )
                }
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 20)
                .animation(.spring(response: 0.5).delay(0.1), value: appeared)

                Button { showAirlinePicker = true } label: {
                    HStack(spacing: 14) {
                        Image(systemName: "airplane.circle.fill")
                            .font(.title3)
                            .foregroundStyle(.white)
                            .frame(width: 44, height: 44)
                            .background(
                                Circle()
                                    .fill(.white.opacity(viewModel.favoriteAirline != nil ? 0.25 : 0.1))
                            )

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Favorite Airline")
                                .font(.headline)
                                .foregroundStyle(.white)
                            if let airline = viewModel.favoriteAirline {
                                Text("\(airline.iata) — \(airline.name)")
                                    .font(.caption)
                                    .foregroundStyle(.white.opacity(0.7))
                                    .lineLimit(1)
                            } else {
                                Text("Tap to select")
                                    .font(.caption)
                                    .foregroundStyle(.white.opacity(0.5))
                            }
                        }

                        Spacer()

                        if viewModel.favoriteAirline != nil {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.title3)
                                .foregroundStyle(.white)
                                .transition(.scale.combined(with: .opacity))
                        } else {
                            Image(systemName: "chevron.right")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.white.opacity(0.5))
                        }
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(viewModel.favoriteAirline != nil ? .white.opacity(0.2) : .white.opacity(0.08))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .strokeBorder(viewModel.favoriteAirline != nil ? .white.opacity(0.5) : .white.opacity(0.12), lineWidth: viewModel.favoriteAirline != nil ? 2 : 1)
                            )
                    )
                }
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 20)
                .animation(.spring(response: 0.5).delay(0.2), value: appeared)
            }

            Button {
                withAnimation(.snappy) { currentPage += 1 }
            } label: {
                Text("Continue")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(.white.opacity(0.25))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .strokeBorder(.white.opacity(0.4), lineWidth: 1)
                            )
                    )
            }
            .opacity(appeared ? 1 : 0)
            .animation(.spring(response: 0.5).delay(0.3), value: appeared)

            Spacer()
        }
        .padding(.horizontal, 24)
        .onAppear {
            withAnimation(.easeIn(duration: 0.5)) { appeared = true }
        }
        .sheet(isPresented: $showAirportPicker) {
            AirportPickerView(selectedAirport: Binding(
                get: { viewModel.homeAirport },
                set: { viewModel.homeAirport = $0 }
            ))
        }
        .sheet(isPresented: $showAirlinePicker) {
            AirlinePickerView(selectedAirline: Binding(
                get: { viewModel.favoriteAirline },
                set: { viewModel.favoriteAirline = $0 }
            ))
        }
    }
}
