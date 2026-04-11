import SwiftUI
import RevenueCat

@main
struct TurbyTurbulenceForecastApp: App {
    @State private var viewModel = AppViewModel()

    init() {
        #if DEBUG
        Purchases.logLevel = .debug
        #endif
        let testKey = Config.EXPO_PUBLIC_REVENUECAT_TEST_API_KEY
        let prodKey = Config.EXPO_PUBLIC_REVENUECAT_IOS_API_KEY
        let apiKey = !prodKey.isEmpty ? prodKey : testKey
        if !apiKey.isEmpty {
            Purchases.configure(withAPIKey: apiKey)
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView(viewModel: viewModel)
                .preferredColorScheme(viewModel.appearanceMode.colorScheme)
                .onAppear {
                    viewModel.subscriptionService.configure()
                }
        }
    }
}
