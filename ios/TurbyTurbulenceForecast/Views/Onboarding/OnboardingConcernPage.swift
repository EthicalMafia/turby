import SwiftUI

struct OnboardingConcernPage: View {
    @Binding var currentPage: Int
    @State private var appeared = false
    @State private var selectedIndex: Int? = nil

    private let concerns: [(icon: String, title: String, subtitle: String)] = [
        ("cloud.bolt.fill", "Turbulence", "I worry about bumpy flights"),
        ("airplane.departure", "Takeoff & Landing", "Those moments make me tense"),
        ("clock.fill", "Long Flights", "Extended time in the air stresses me"),
        ("questionmark.circle.fill", "Not Knowing", "Uncertainty is the worst part"),
        ("hand.thumbsup.fill", "I'm Actually Fine", "Just want better info")
    ]

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            VStack(spacing: 12) {
                Image(systemName: "thought.bubble.fill")
                    .font(.system(size: 48, weight: .light))
                    .foregroundStyle(.white)
                    .symbolEffect(.pulse, options: .repeating)

                Text("What concerns you\nmost about flying?")
                    .font(.system(.title2, design: .default, weight: .bold))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)

                Text("This helps us focus on what matters to you")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.75))
            }

            VStack(spacing: 10) {
                ForEach(Array(concerns.enumerated()), id: \.offset) { index, concern in
                    Button {
                        withAnimation(.snappy) { selectedIndex = index }
                    } label: {
                        HStack(spacing: 14) {
                            Image(systemName: concern.icon)
                                .font(.title3)
                                .foregroundStyle(.white)
                                .frame(width: 40, height: 40)
                                .background(
                                    Circle()
                                        .fill(.white.opacity(selectedIndex == index ? 0.25 : 0.1))
                                )

                            VStack(alignment: .leading, spacing: 2) {
                                Text(concern.title)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(.white)
                                Text(concern.subtitle)
                                    .font(.caption)
                                    .foregroundStyle(.white.opacity(0.7))
                            }

                            Spacer()

                            if selectedIndex == index {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.title3)
                                    .foregroundStyle(.white)
                                    .transition(.scale.combined(with: .opacity))
                            }
                        }
                        .padding(14)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(selectedIndex == index ? .white.opacity(0.2) : .white.opacity(0.08))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14)
                                        .strokeBorder(selectedIndex == index ? .white.opacity(0.5) : .white.opacity(0.12), lineWidth: selectedIndex == index ? 2 : 1)
                                )
                        )
                    }
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 20)
                    .animation(.spring(response: 0.5).delay(Double(index) * 0.08), value: appeared)
                }
            }

            if selectedIndex != nil {
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
                .transition(.opacity.combined(with: .move(edge: .bottom)))
            }

            Spacer()
        }
        .padding(.horizontal, 24)
        .onAppear {
            withAnimation(.easeIn(duration: 0.5)) { appeared = true }
        }
        .sensoryFeedback(.selection, trigger: selectedIndex)
    }
}
