import SwiftUI

struct ShimmerLoadingView: View {
    @State private var planeOffset: CGFloat = -1.0
    @State private var dotPhase: Int = 0
    @Environment(\.colorScheme) private var colorScheme

    private let statusMessages = [
        "Checking flight data",
        "Analyzing weather along your route",
        "Evaluating turbulence risk",
        "Building your forecast"
    ]

    @State private var messageIndex: Int = 0

    var body: some View {
        VStack(spacing: 20) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(TurbyTurbulenceForecastTheme.accent.opacity(0.06))
                    .frame(height: 80)

                routeLine

                Image(systemName: "airplane")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(TurbyTurbulenceForecastTheme.accent)
                    .offset(x: planeOffset * 100)
            }

            VStack(spacing: 8) {
                Text(statusMessages[messageIndex] + dots)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.primary)
                    .contentTransition(.numericText())
                    .animation(.easeInOut(duration: 0.3), value: messageIndex)

                Text("This usually takes a few seconds")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }

            HStack(spacing: 12) {
                ShimmerBlock(height: 50)
                ShimmerBlock(height: 50)
                ShimmerBlock(height: 50)
            }

            ShimmerBlock(height: 20)
            ShimmerBlock(width: 180, height: 14)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.06), radius: 16, y: 6)
        )
        .onAppear {
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                planeOffset = 1.0
            }
            startMessageRotation()
            startDotAnimation()
        }
    }

    private var routeLine: some View {
        HStack(spacing: 0) {
            ForEach(0..<20, id: \.self) { i in
                Circle()
                    .fill(TurbyTurbulenceForecastTheme.accent.opacity(0.15))
                    .frame(width: 3, height: 3)
                if i < 19 {
                    Spacer()
                }
            }
        }
        .padding(.horizontal, 30)
    }

    private var dots: String {
        String(repeating: ".", count: (dotPhase % 3) + 1)
    }

    private func startMessageRotation() {
        Task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(2.5))
                guard !Task.isCancelled else { return }
                withAnimation {
                    messageIndex = (messageIndex + 1) % statusMessages.count
                }
            }
        }
    }

    private func startDotAnimation() {
        Task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(500))
                guard !Task.isCancelled else { return }
                dotPhase += 1
            }
        }
    }
}

struct ShimmerBlock: View {
    var width: CGFloat? = nil
    var height: CGFloat = 16
    @State private var shimmerOffset: CGFloat = -200

    var body: some View {
        RoundedRectangle(cornerRadius: 6)
            .fill(Color(.systemGray5))
            .frame(maxWidth: width ?? .infinity)
            .frame(height: height)
            .overlay(
                GeometryReader { geo in
                    LinearGradient(
                        colors: [.clear, Color(.systemGray4).opacity(0.5), .clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: 100)
                    .offset(x: shimmerOffset)
                    .onAppear {
                        withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                            shimmerOffset = geo.size.width + 100
                        }
                    }
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}
