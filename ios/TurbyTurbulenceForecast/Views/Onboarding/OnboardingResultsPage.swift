import SwiftUI

struct OnboardingResultsPage: View {
    let viewModel: AppViewModel
    @Binding var currentPage: Int
    @State private var appeared = false
    @State private var checkmarks: [Bool] = [false, false, false, false]

    var body: some View {
        VStack(spacing: 28) {
            Spacer()

            VStack(spacing: 16) {
                Image(systemName: "sparkles")
                    .font(.system(size: 48, weight: .light))
                    .foregroundStyle(.yellow)
                    .symbolEffect(.variableColor.iterative, options: .repeating)

                Text("Your personalized\nplan is ready!")
                    .font(.system(.title, design: .default, weight: .bold))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)

                Text("Based on your answers, here's what\nwe've prepared for you")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
            }

            VStack(spacing: 12) {
                ResultCheckRow(
                    icon: "person.crop.circle.badge.checkmark",
                    text: "\(viewModel.passengerProfile.title) mode activated",
                    isChecked: checkmarks[0]
                )
                ResultCheckRow(
                    icon: "chart.line.uptrend.xyaxis",
                    text: "Personalized turbulence insights",
                    isChecked: checkmarks[1]
                )
                ResultCheckRow(
                    icon: "heart.text.clipboard",
                    text: "Tailored reassurance & tips",
                    isChecked: checkmarks[2]
                )
                ResultCheckRow(
                    icon: "bell.badge.fill",
                    text: "Smart pre-flight alerts",
                    isChecked: checkmarks[3]
                )
            }

            Button {
                withAnimation(.snappy) { currentPage += 1 }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                    Text("Find My Flight")
                }
                .font(.headline)
                .foregroundStyle(Color(red: 0.22, green: 0.45, blue: 0.78))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.white)
                )
            }

            Spacer()
        }
        .padding(.horizontal, 24)
        .opacity(appeared ? 1 : 0)
        .onAppear {
            withAnimation(.easeIn(duration: 0.4)) { appeared = true }
            for i in 0..<4 {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5 + Double(i) * 0.4) {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                        checkmarks[i] = true
                    }
                }
            }
        }
    }
}

struct ResultCheckRow: View {
    let icon: String
    let text: String
    let isChecked: Bool

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(isChecked ? .white.opacity(0.25) : .white.opacity(0.08))
                    .frame(width: 40, height: 40)

                if isChecked {
                    Image(systemName: "checkmark")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(.white)
                        .transition(.scale.combined(with: .opacity))
                } else {
                    Image(systemName: icon)
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.5))
                }
            }

            Text(text)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.white.opacity(isChecked ? 1 : 0.5))

            Spacer()
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(isChecked ? .white.opacity(0.12) : .white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .strokeBorder(isChecked ? .white.opacity(0.3) : .white.opacity(0.08), lineWidth: 1)
                )
        )
    }
}
