import SwiftUI
import RevenueCat

struct ExitIntentView: View {
    let viewModel: AppViewModel
    @State private var appeared = false
    @State private var pulseTimer = false

    private var weeklyPackage: Package? {
        viewModel.subscriptionService.weeklyPackage
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.6)
                .ignoresSafeArea()
                .onTapGesture { viewModel.dismissExitIntent() }

            VStack(spacing: 24) {
                VStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(TurbyTurbulenceForecastTheme.accent.opacity(0.12))
                            .frame(width: 72, height: 72)
                            .scaleEffect(pulseTimer ? 1.1 : 1.0)
                            .animation(.easeInOut(duration: 1).repeatForever(autoreverses: true), value: pulseTimer)
                        Image(systemName: "airplane.circle.fill")
                            .font(.system(size: 32))
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(TurbyTurbulenceForecastTheme.accent)
                    }

                    Text("Not ready to commit?")
                        .font(.title2.weight(.bold))

                    Text("Try Turby for just one week —\nno long-term commitment")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)

                    HStack(spacing: 4) {
                        Image(systemName: "heart.fill")
                            .font(.caption)
                        Text("Cancel anytime")
                            .font(.caption.weight(.medium))
                    }
                    .foregroundStyle(TurbyTurbulenceForecastTheme.accent)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(TurbyTurbulenceForecastTheme.accent.opacity(0.12)))
                }

                if let pkg = weeklyPackage {
                    VStack(spacing: 4) {
                        Text("Just \(pkg.storeProduct.localizedPriceString)/week")
                            .font(.title3.weight(.bold))
                            .foregroundStyle(TurbyTurbulenceForecastTheme.accent)
                        Text("Full access to all features")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Button {
                    if let pkg = weeklyPackage {
                        Task { await viewModel.purchasePackage(pkg) }
                    }
                } label: {
                    Text("Try for \(weeklyPackage?.storeProduct.localizedPriceString ?? "")/week")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
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
                .sensoryFeedback(.impact(weight: .heavy), trigger: viewModel.subscriptionService.isProcessing)

                Button {
                    viewModel.dismissExitIntent()
                } label: {
                    Text("No thanks")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(28)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.25), radius: 30, y: 10)
            )
            .padding(.horizontal, 32)
            .scaleEffect(appeared ? 1 : 0.8)
            .opacity(appeared ? 1 : 0)
        }
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                appeared = true
            }
            pulseTimer = true
        }
    }
}
