import SwiftUI

struct OnboardingView: View {
    let viewModel: AppViewModel
    @State private var currentPage: Int = 0
    @State private var appeared = false

    private let totalPages = 11

    var body: some View {
        ZStack {
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
            .ignoresSafeArea()

            VStack(spacing: 0) {
                TabView(selection: $currentPage) {
                    OnboardingHookPage()
                        .tag(0)
                    OnboardingTrustPage()
                        .tag(1)
                    OnboardingNamePage(viewModel: viewModel, currentPage: $currentPage)
                        .tag(2)
                    OnboardingProfilePage(viewModel: viewModel, currentPage: $currentPage)
                        .tag(3)
                    OnboardingPreferencesPage(viewModel: viewModel, currentPage: $currentPage)
                        .tag(4)
                    OnboardingConcernPage(currentPage: $currentPage)
                        .tag(5)
                    OnboardingFrequencyPage(currentPage: $currentPage)
                        .tag(6)
                    OnboardingDemoPage()
                        .tag(7)
                    OnboardingRatingPage(currentPage: $currentPage, viewModel: viewModel)
                        .tag(8)
                    OnboardingResultsPage(viewModel: viewModel, currentPage: $currentPage)
                        .tag(9)
                    OnboardingInputPage(viewModel: viewModel, currentPage: $currentPage)
                        .tag(10)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.smooth, value: currentPage)

                VStack(spacing: 16) {
                    PageIndicator(currentPage: currentPage, totalPages: totalPages)

                    if currentPage < 2 {
                        Button {
                            withAnimation(.snappy) { currentPage += 1 }
                        } label: {
                            Text(currentPage == 0 ? "Check My Flight" : "Continue")
                                .font(.headline)
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(.white.opacity(0.15))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 16)
                                                .strokeBorder(.white.opacity(0.3), lineWidth: 1)
                                        )
                                )
                        }
                        .padding(.horizontal, 24)
                    } else if currentPage == 7 {
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
                                        .fill(.white.opacity(0.15))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 16)
                                                .strokeBorder(.white.opacity(0.3), lineWidth: 1)
                                        )
                                )
                        }
                        .padding(.horizontal, 24)
                    }
                }
                .padding(.bottom, 20)
            }
        }
        .opacity(appeared ? 1 : 0)
        .onAppear { withAnimation(.easeIn(duration: 0.5)) { appeared = true } }
        .sensoryFeedback(.selection, trigger: currentPage)
    }
}

struct PageIndicator: View {
    let currentPage: Int
    let totalPages: Int

    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<totalPages, id: \.self) { index in
                Capsule()
                    .fill(index == currentPage ? .white : .white.opacity(0.25))
                    .frame(width: index == currentPage ? 20 : 6, height: 6)
                    .animation(.snappy, value: currentPage)
            }
        }
        .padding(.vertical, 12)
    }
}
