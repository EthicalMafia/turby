import SwiftUI

struct OnboardingTrustPage: View {
    @State private var appeared = false

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            Image(systemName: "shield.checkered")
                .font(.system(size: 64))
                .foregroundStyle(.white)
                .symbolEffect(.pulse, options: .repeating)

            VStack(spacing: 20) {
                Text("73% of passengers\nfeel anxious about turbulence")
                    .font(.system(.title2, design: .default, weight: .bold))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)

                Text("You're not alone. Turby gives you the\nknowledge that turns fear into confidence.")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)

                VStack(spacing: 12) {
                    StatBubble(
                        icon: "checkmark.shield.fill",
                        text: "No modern aircraft has ever crashed due to turbulence",
                        delay: 0.1
                    )
                    StatBubble(
                        icon: "person.2.fill",
                        text: "100,000+ flights land safely every single day",
                        delay: 0.3
                    )
                    StatBubble(
                        icon: "heart.fill",
                        text: "Turby users report 80% less flight anxiety",
                        delay: 0.5
                    )
                }
            }

            Spacer()
            Spacer()
        }
        .padding(.horizontal, 24)
    }
}

struct StatBubble: View {
    let icon: String
    let text: String
    let delay: Double
    @State private var appeared = false

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.white)
                .frame(width: 36)

            Text(text)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.9))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(.white.opacity(0.12))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .strokeBorder(.white.opacity(0.15), lineWidth: 1)
                )
        )
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 15)
        .onAppear {
            withAnimation(.spring(response: 0.5).delay(delay)) {
                appeared = true
            }
        }
    }
}
