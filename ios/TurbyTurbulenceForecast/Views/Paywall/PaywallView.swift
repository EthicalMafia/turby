import SwiftUI
import RevenueCat

struct PaywallView: View {
    let viewModel: AppViewModel
    @State private var selectedPackage: Package?
    @State private var appeared = false
    @State private var featureIndex = 0

    private var packages: [Package] {
        viewModel.subscriptionService.sortedPackages
    }

    var body: some View {
        ZStack {
            backgroundGradient
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 28) {
                    HStack {
                        Spacer()
                        Button {
                            viewModel.dismissPaywall()
                        } label: {
                            Image(systemName: "xmark")
                                .font(.body.weight(.semibold))
                                .foregroundStyle(.white.opacity(0.6))
                                .frame(width: 34, height: 34)
                                .background(Circle().fill(.white.opacity(0.1)))
                        }
                    }
                    .padding(.top, 8)

                    heroSection

                    featuresGrid

                    BlurredPreviewCard()

                    plansSection

                    ctaButton

                    footerLinks
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 20)
            }
            .scrollIndicators(.hidden)
        }
        .opacity(appeared ? 1 : 0)
        .onAppear {
            withAnimation(.easeIn(duration: 0.3)) { appeared = true }
            if selectedPackage == nil {
                selectedPackage = viewModel.subscriptionService.annualPackage ?? packages.last
            }
            if viewModel.subscriptionService.offerings == nil && !viewModel.subscriptionService.isLoadingOfferings {
                Task { await viewModel.subscriptionService.fetchOfferings() }
            }
        }
        .onChange(of: packages) { _, newPackages in
            if selectedPackage == nil, let first = viewModel.subscriptionService.annualPackage ?? newPackages.last {
                selectedPackage = first
            }
        }
        .onChange(of: viewModel.subscriptionService.isSubscribed) { _, subscribed in
            if subscribed {
                viewModel.showPaywall = false
                viewModel.showExitIntent = false
            }
        }
    }

    private var backgroundGradient: some View {
        MeshGradient(width: 3, height: 3, points: [
            [0, 0], [0.5, 0], [1, 0],
            [0, 0.5], [0.5, 0.5], [1, 0.5],
            [0, 1], [0.5, 1], [1, 1]
        ], colors: [
            Color(red: 0.08, green: 0.10, blue: 0.22),
            Color(red: 0.12, green: 0.18, blue: 0.38),
            Color(red: 0.08, green: 0.12, blue: 0.28),
            Color(red: 0.10, green: 0.16, blue: 0.35),
            Color(red: 0.16, green: 0.25, blue: 0.50),
            Color(red: 0.10, green: 0.18, blue: 0.38),
            Color(red: 0.06, green: 0.08, blue: 0.18),
            Color(red: 0.10, green: 0.14, blue: 0.30),
            Color(red: 0.08, green: 0.10, blue: 0.22)
        ])
    }

    private var heroSection: some View {
        VStack(spacing: 16) {
            TurbyTurbulenceForecastLogo(style: .onboarding)
                .padding(.bottom, 4)

            Text("Fly with\nConfidence")
                .font(.system(size: 34, weight: .bold))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .lineSpacing(2)

            Text("Everything you need to feel calm\nand informed before takeoff")
                .font(.body)
                .foregroundStyle(.white.opacity(0.7))
                .multilineTextAlignment(.center)
        }
    }

    private var featuresGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            FeatureCell(icon: "chart.bar.fill", title: "Turbulence\nBreakdown", color: TurbyTurbulenceForecastTheme.accent)
            FeatureCell(icon: "map.fill", title: "Route\nMap", color: Color(red: 0.20, green: 0.78, blue: 0.55))
            FeatureCell(icon: "chair.lounge.fill", title: "Best Seat\nTips", color: Color(red: 0.95, green: 0.75, blue: 0.20))
            FeatureCell(icon: "heart.circle.fill", title: "Calm\nMode", color: Color(red: 0.85, green: 0.40, blue: 0.55))
            FeatureCell(icon: "arrow.left.arrow.right", title: "Compare\nFlights", color: Color(red: 0.55, green: 0.45, blue: 0.85))
            FeatureCell(icon: "bell.fill", title: "Real-time\nAlerts", color: Color(red: 0.95, green: 0.50, blue: 0.20))
        }
    }

    private var plansSection: some View {
        VStack(spacing: 10) {
            if viewModel.subscriptionService.isLoadingOfferings {
                ProgressView()
                    .tint(.white)
                    .padding(.vertical, 20)
            } else if packages.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "wifi.exclamationmark")
                        .font(.title2)
                        .foregroundStyle(.white.opacity(0.7))
                    Text("Couldn't load plans")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.white.opacity(0.8))
                    Text("Plans load on real devices via TestFlight.\nThis is expected in the simulator.")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.5))
                        .multilineTextAlignment(.center)
                    Button {
                        Task { await viewModel.subscriptionService.fetchOfferings() }
                    } label: {
                        Text("Try Again")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 10)
                            .background(Capsule().fill(.white.opacity(0.15)))
                    }
                }
                .padding(.vertical, 20)
            } else {
                ForEach(packages, id: \.identifier) { package in
                    RCPlanCard(
                        package: package,
                        isSelected: selectedPackage?.identifier == package.identifier
                    ) {
                        withAnimation(.snappy) { selectedPackage = package }
                    }
                }
            }
        }
    }

    private var ctaButton: some View {
        Button {
            guard let pkg = selectedPackage else { return }
            Task { await viewModel.purchasePackage(pkg) }
        } label: {
            HStack(spacing: 8) {
                if viewModel.subscriptionService.isProcessing {
                    ProgressView()
                        .tint(Color(red: 0.12, green: 0.18, blue: 0.38))
                } else if let pkg = selectedPackage {
                    Text("Start My Plan — \(pkg.storeProduct.localizedPriceString)/\(pkg.periodLabel)")
                } else {
                    Text("Select a plan")
                }
            }
            .font(.headline)
            .foregroundStyle(Color(red: 0.10, green: 0.16, blue: 0.35))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.white)
                    .shadow(color: .white.opacity(0.2), radius: 12, y: 4)
            )
        }
        .disabled(viewModel.subscriptionService.isProcessing || selectedPackage == nil)
        .sensoryFeedback(.impact(weight: .medium), trigger: viewModel.subscriptionService.isProcessing)
    }

    private var footerLinks: some View {
        VStack(spacing: 12) {
            HStack(spacing: 16) {
                Button {
                    Task { _ = await viewModel.subscriptionService.restorePurchases() }
                } label: {
                    Text("Restore Purchases")
                        .font(.footnote)
                        .foregroundStyle(.white.opacity(0.5))
                }

                Text("\u{2022}")
                    .foregroundStyle(.white.opacity(0.2))

                Button {
                    if let url = URL(string: "https://turby.app/terms") {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    Text("Terms")
                        .font(.footnote)
                        .foregroundStyle(.white.opacity(0.5))
                }

                Text("\u{2022}")
                    .foregroundStyle(.white.opacity(0.2))

                Button {
                    if let url = URL(string: "https://turby.app/privacy") {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    Text("Privacy")
                        .font(.footnote)
                        .foregroundStyle(.white.opacity(0.5))
                }
            }

            Text("Cancel anytime. No commitment.")
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.3))
        }
    }
}

struct FeatureCell: View {
    let icon: String
    let title: String
    let color: Color

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(color)
                .frame(width: 24)
            Text(title)
                .font(.caption.weight(.medium))
                .foregroundStyle(.white.opacity(0.9))
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
            Spacer()
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(.white.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .strokeBorder(.white.opacity(0.08), lineWidth: 0.5)
                )
        )
    }
}

struct BlurredPreviewCard: View {
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text("AA 1234").font(.headline)
                Spacer()
                Text("JFK \u{2192} LAX").font(.subheadline).foregroundStyle(.secondary)
            }
            HStack(spacing: 16) {
                VStack { Text("\u{1F7E2}"); Text("Smooth").font(.caption) }
                VStack { Text("\u{1F7E1}"); Text("Light").font(.caption) }
                VStack { Text("\u{1F7E2}"); Text("Smooth").font(.caption) }
            }
            .frame(maxWidth: .infinity)
            Text("Score: 2/10")
                .font(.title3.weight(.bold))
                .foregroundStyle(.green)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
        )
        .blur(radius: 6)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(.white.opacity(0.2), lineWidth: 1)
        )
        .overlay {
            VStack(spacing: 8) {
                Image(systemName: "lock.fill")
                    .font(.title)
                    .foregroundStyle(.white)
                Text("Your forecast is waiting")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.white.opacity(0.8))
            }
        }
        .allowsHitTesting(false)
    }
}

struct RCPlanCard: View {
    let package: Package
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 8) {
                        Text(package.periodLabel.capitalized)
                            .font(.headline)
                            .foregroundStyle(.white)
                        if package.packageType == .annual {
                            Text("BEST VALUE")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(
                                    Capsule()
                                        .fill(
                                            LinearGradient(
                                                colors: [Color(red: 0.20, green: 0.78, blue: 0.55), Color(red: 0.15, green: 0.65, blue: 0.45)],
                                                startPoint: .leading, endPoint: .trailing
                                            )
                                        )
                                )
                        }
                    }
                    if let weeklyText = package.weeklyEquivalentText {
                        Text(weeklyText)
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.5))
                    }
                }

                Spacer()

                Text(package.storeProduct.localizedPriceString)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.white)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(isSelected ? .white.opacity(0.15) : .white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .strokeBorder(isSelected ? .white.opacity(0.5) : .white.opacity(0.1), lineWidth: isSelected ? 1.5 : 0.5)
                    )
            )
        }
        .sensoryFeedback(.selection, trigger: isSelected)
    }
}

extension Package {
    var periodLabel: String {
        switch packageType {
        case .weekly: "week"
        case .monthly: "month"
        case .annual: "year"
        default: storeProduct.localizedTitle
        }
    }

    var weeklyEquivalentText: String? {
        guard let price = storeProduct.price as Decimal? else { return nil }
        switch packageType {
        case .monthly:
            let weekly = price / 4.33
            return "\(formatPrice(weekly))/wk"
        case .annual:
            let weekly = price / 52.0
            return "\(formatPrice(weekly))/wk"
        default:
            return nil
        }
    }

    private func formatPrice(_ value: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = storeProduct.priceFormatter?.locale ?? .current
        formatter.maximumFractionDigits = 2
        return formatter.string(from: value as NSDecimalNumber) ?? ""
    }
}
