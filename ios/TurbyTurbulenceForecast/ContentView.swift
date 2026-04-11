import SwiftUI

struct ContentView: View {
    let viewModel: AppViewModel

    var body: some View {
        if viewModel.hasCompletedOnboarding {
            MainTabView(viewModel: viewModel)
                .transition(.opacity)
        } else {
            OnboardingView(viewModel: viewModel)
                .transition(.opacity)
        }
    }
}

struct MainTabView: View {
    let viewModel: AppViewModel

    var body: some View {
        TabView(selection: Binding(
            get: { viewModel.selectedTab },
            set: { viewModel.selectedTab = $0 }
        )) {
            Tab("Forecast", systemImage: "cloud.sun.fill", value: 0) {
                HomeView(viewModel: viewModel)
            }
            Tab("Calm", systemImage: "heart.circle.fill", value: 1) {
                CalmModeView()
            }
            Tab("History", systemImage: "clock.arrow.circlepath", value: 2) {
                FlightHistoryView(viewModel: viewModel)
            }
            Tab("Settings", systemImage: "gearshape.fill", value: 3) {
                SettingsView(viewModel: viewModel)
            }
        }
        .tint(TurbyTurbulenceForecastTheme.accent)
    }
}
