import SwiftUI

struct OnboardingProfilePage: View {
    let viewModel: AppViewModel
    @Binding var currentPage: Int
    @State private var appeared = false
    @State private var selectedIndex: Int? = nil

    var body: some View {
        VStack(spacing: 28) {
            Spacer()

            VStack(spacing: 12) {
                Image(systemName: "person.crop.circle.badge.checkmark")
                    .font(.system(size: 52, weight: .light))
                    .foregroundStyle(.white)
                    .symbolEffect(.pulse, options: .repeating)

                Text("How do you fly?")
                    .font(.system(.title, design: .default, weight: .bold))
                    .foregroundStyle(.white)

                Text("We'll personalize your experience")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.75))
            }

            VStack(spacing: 12) {
                ForEach(Array(PassengerProfile.allCases.enumerated()), id: \.element) { index, profile in
                    Button {
                        withAnimation(.snappy) {
                            selectedIndex = index
                            viewModel.passengerProfile = profile
                        }
                    } label: {
                        HStack(spacing: 14) {
                            Image(systemName: profile.icon)
                                .font(.title3)
                                .foregroundStyle(.white)
                                .frame(width: 44, height: 44)
                                .background(
                                    Circle()
                                        .fill(.white.opacity(selectedIndex == index ? 0.25 : 0.1))
                                )

                            VStack(alignment: .leading, spacing: 2) {
                                Text(profile.title)
                                    .font(.headline)
                                    .foregroundStyle(.white)
                                Text(profile.subtitle)
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
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(selectedIndex == index ? .white.opacity(0.2) : .white.opacity(0.08))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .strokeBorder(selectedIndex == index ? .white.opacity(0.5) : .white.opacity(0.12), lineWidth: selectedIndex == index ? 2 : 1)
                                )
                        )
                    }
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 20)
                    .animation(.spring(response: 0.5).delay(Double(index) * 0.1), value: appeared)
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
