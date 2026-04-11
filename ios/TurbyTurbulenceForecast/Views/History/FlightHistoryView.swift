import SwiftUI

struct FlightHistoryView: View {
    let viewModel: AppViewModel
    @Environment(\.colorScheme) private var colorScheme
    @State private var selectedForecast: FlightForecast?


    var body: some View {
        NavigationStack {
            ZStack {
                TurbyTurbulenceForecastTheme.calmBackground(for: colorScheme)
                    .ignoresSafeArea()

                if viewModel.historyService.entries.isEmpty {
                    emptyState
                } else {
                    historyList
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Flight History")
                        .font(.headline)
                }
                if !viewModel.historyService.entries.isEmpty {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Clear All", role: .destructive) {
                            withAnimation { viewModel.historyService.clearAll() }
                        }
                        .font(.subheadline)
                    }
                }
            }
            .sheet(item: $selectedForecast) { forecast in
                NavigationStack {
                    ScrollView {
                        VStack(spacing: 16) {
                            ForecastResultView(
                                forecast: forecast,
                                isPilotMode: viewModel.isPilotMode,
                                profile: viewModel.passengerProfile,
                                flightService: viewModel.flightService
                            )
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                        .padding(.bottom, 40)
                    }
                    .scrollIndicators(.hidden)
                    .background(TurbyTurbulenceForecastTheme.calmBackground(for: colorScheme).ignoresSafeArea())
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .principal) {
                            Text(forecast.flightNumber)
                                .font(.headline)
                        }
                        ToolbarItem(placement: .topBarTrailing) {
                            Button("Done") { selectedForecast = nil }
                        }
                    }
                }
                .presentationDetents([.large])
            }
            .sheet(isPresented: Binding(
                get: { viewModel.showPaywall },
                set: { viewModel.showPaywall = $0 }
            )) {
                PaywallView(viewModel: viewModel)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(TurbyTurbulenceForecastTheme.accent.opacity(0.08))
                    .frame(width: 88, height: 88)
                Image(systemName: "clock.arrow.circlepath")
                    .font(.system(size: 38))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(TurbyTurbulenceForecastTheme.accent)
            }

            Text("No Flight History")
                .font(.title3.weight(.semibold))

            Text("Your searched flights will appear here\nso you can revisit them anytime.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(40)
    }

    private var historyList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(viewModel.historyService.entries) { entry in
                    HistoryCard(entry: entry) {
                        if viewModel.subscriptionService.isSubscribed {
                            selectedForecast = entry.forecast
                        } else {
                            viewModel.showPaywall = true
                        }
                    }
                    .transition(.opacity.combined(with: .slide))
                    .contextMenu {
                        Button(role: .destructive) {
                            withAnimation {
                                viewModel.historyService.deleteEntry(entry)
                            }
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 40)
        }
        .scrollIndicators(.hidden)
    }
}

struct HistoryCard: View {
    let entry: FlightHistoryEntry
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(TurbyTurbulenceForecastTheme.scoreColor(for: entry.overallScore).opacity(0.12))
                        .frame(width: 52, height: 52)
                    Text("\(entry.overallScore)")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(TurbyTurbulenceForecastTheme.scoreColor(for: entry.overallScore))
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(entry.flightNumber)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                    HStack(spacing: 6) {
                        Text(entry.departureCode)
                            .font(.caption.weight(.medium))
                        Image(systemName: "arrow.right")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                        Text(entry.arrivalCode)
                            .font(.caption.weight(.medium))
                    }
                    .foregroundStyle(.secondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text(entry.date, style: .date)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(entry.turbulenceLevel.label)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(TurbyTurbulenceForecastTheme.turbulenceColor(for: entry.turbulenceLevel))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(
                            Capsule()
                                .fill(TurbyTurbulenceForecastTheme.turbulenceColor(for: entry.turbulenceLevel).opacity(0.12))
                        )
                }

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(16)
            .glassCard()
        }
        .buttonStyle(.plain)
    }
}
