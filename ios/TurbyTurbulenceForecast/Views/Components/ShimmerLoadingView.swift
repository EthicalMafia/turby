import SwiftUI

struct ShimmerLoadingView: View {
    @State private var phase: CGFloat = -1.0

    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 12) {
                ShimmerBlock(width: 80, height: 14)
                Spacer()
                ShimmerBlock(width: 60, height: 14)
            }

            ShimmerBlock(height: 40)

            HStack(spacing: 12) {
                ShimmerBlock(height: 60)
                ShimmerBlock(height: 60)
                ShimmerBlock(height: 60)
            }

            ShimmerBlock(height: 20)
            ShimmerBlock(width: 200, height: 14)

            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("Analyzing weather data along your route...")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 4)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.06), radius: 16, y: 6)
        )
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
