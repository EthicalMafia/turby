import Foundation
import RevenueCat

@Observable
@MainActor
class SubscriptionService {
    var isSubscribed: Bool = false
    var isProcessing: Bool = false
    var offerings: Offerings?
    var error: String?
    var isLoadingOfferings: Bool = false
    private var isConfigured: Bool = false

    func configure() {
        guard !isConfigured else { return }
        isConfigured = true
        Task { await listenForUpdates() }
        Task { await fetchOfferings() }
    }

    private func listenForUpdates() async {
        for await info in Purchases.shared.customerInfoStream {
            self.isSubscribed = info.entitlements["premium"]?.isActive == true
        }
    }

    func fetchOfferings() async {
        guard !isLoadingOfferings else { return }
        isLoadingOfferings = true
        error = nil
        
        for attempt in 1...3 {
            do {
                let result = try await Purchases.shared.offerings()
                offerings = result
                if result.current != nil {
                    error = nil
                    isLoadingOfferings = false
                    return
                }
            } catch {
                if attempt == 3 {
                    self.error = "Couldn't load plans. Please check your connection and try again."
                }
            }
            if attempt < 3 {
                try? await Task.sleep(for: .seconds(Double(attempt)))
            }
        }
        
        if offerings?.current == nil && error == nil {
            error = "No plans available right now. Please try again later."
        }
        isLoadingOfferings = false
    }

    func purchase(package: Package) async -> Bool {
        isProcessing = true
        defer { isProcessing = false }
        do {
            let result = try await Purchases.shared.purchase(package: package)
            if !result.userCancelled {
                isSubscribed = result.customerInfo.entitlements["premium"]?.isActive == true
                return isSubscribed
            }
            return false
        } catch ErrorCode.purchaseCancelledError {
            return false
        } catch ErrorCode.paymentPendingError {
            return false
        } catch {
            self.error = error.localizedDescription
            return false
        }
    }

    func restorePurchases() async -> Bool {
        isProcessing = true
        defer { isProcessing = false }
        do {
            let info = try await Purchases.shared.restorePurchases()
            isSubscribed = info.entitlements["premium"]?.isActive == true
            return isSubscribed
        } catch {
            self.error = error.localizedDescription
            return false
        }
    }

    func checkStatus() async {
        do {
            let info = try await Purchases.shared.customerInfo()
            isSubscribed = info.entitlements["premium"]?.isActive == true
        } catch {
            self.error = error.localizedDescription
        }
    }

    var currentOffering: Offering? {
        offerings?.current
    }

    var weeklyPackage: Package? {
        currentOffering?.availablePackages.first { $0.packageType == .weekly }
    }

    var monthlyPackage: Package? {
        currentOffering?.availablePackages.first { $0.packageType == .monthly }
    }

    var annualPackage: Package? {
        currentOffering?.availablePackages.first { $0.packageType == .annual }
    }

    var sortedPackages: [Package] {
        let order: [PackageType] = [.weekly, .monthly, .annual]
        return (currentOffering?.availablePackages ?? []).sorted { a, b in
            let ai = order.firstIndex(of: a.packageType) ?? 99
            let bi = order.firstIndex(of: b.packageType) ?? 99
            return ai < bi
        }
    }
}
