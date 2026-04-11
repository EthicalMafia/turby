import SwiftUI
import StoreKit

struct OnboardingRatingPage: View {
    @Binding var currentPage: Int
    let viewModel: AppViewModel
    @Environment(\.requestReview) private var requestReview
    @State private var appeared = false
    @State private var starsAnimated = false
    @State private var hasRequestedReview = false

    var body: some View {
        VStack(spacing: 28) {
            Spacer()

            VStack(spacing: 20) {
                ZStack {
                    ForEach(0..<3, id: \.self) { i in
                        Circle()
                            .fill(.white.opacity(0.05))
                            .frame(width: CGFloat(120 + i * 40), height: CGFloat(120 + i * 40))
                    }

                    HStack(spacing: 6) {
                        ForEach(0..<5, id: \.self) { i in
                            Image(systemName: "star.fill")
                                .font(.system(size: 28))
                                .foregroundStyle(.yellow)
                                .opacity(starsAnimated ? 1 : 0)
                                .scaleEffect(starsAnimated ? 1 : 0.3)
                                .animation(.spring(response: 0.4, dampingFraction: 0.6).delay(Double(i) * 0.1), value: starsAnimated)
                        }
                    }
                }

                VStack(spacing: 12) {
                    Text("Help Fellow Flyers\nFind Turby")
                        .font(.system(.title, design: .default, weight: .bold))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)

                    Text("Your rating helps nervous and everyday\nflyers get equal access to real-time\nweather on their flights")
                        .font(.body)
                        .foregroundStyle(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            VStack(spacing: 14) {
                HStack(spacing: 12) {
                    Image(systemName: "heart.fill")
                        .foregroundStyle(.pink)
                    Text("Help others overcome flight anxiety")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.9))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(.white.opacity(0.1))
                )

                HStack(spacing: 12) {
                    Image(systemName: "airplane")
                        .foregroundStyle(.cyan)
                    Text("Every rating makes Turby visible to more flyers")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.9))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(.white.opacity(0.1))
                )
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

            Spacer()
        }
        .padding(.horizontal, 24)
        .opacity(appeared ? 1 : 0)
        .onAppear {
            withAnimation(.easeIn(duration: 0.4)) { appeared = true }
            withAnimation(.easeOut(duration: 0.3).delay(0.3)) { starsAnimated = true }
            if !hasRequestedReview {
                requestReview()
                hasRequestedReview = true
                viewModel.didRateInOnboarding = true
            }
        }
    }
}
