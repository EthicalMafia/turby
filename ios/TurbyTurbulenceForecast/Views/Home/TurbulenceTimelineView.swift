import SwiftUI

struct TurbulenceTimelineView: View {
    let forecast: FlightForecast
    @State private var animatedProgress: Double = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Image(systemName: "clock.arrow.circlepath")
                    .foregroundStyle(TurbyTurbulenceForecastTheme.accent)
                Text("Flight Timeline")
                    .font(.headline)
                Spacer()
            }

            VStack(spacing: 0) {
                ForEach(Array(forecast.timeline.enumerated()), id: \.element.id) { index, segment in
                    TimelineRow(
                        segment: segment,
                        isFirst: index == 0,
                        isLast: index == forecast.timeline.count - 1,
                        animatedProgress: animatedProgress,
                        segmentIndex: index,
                        totalSegments: forecast.timeline.count
                    )
                }
            }
        }
        .padding(18)
        .glassCard()
        .onAppear {
            withAnimation(.easeOut(duration: 1.2).delay(0.3)) {
                animatedProgress = 1.0
            }
        }
    }
}

struct TimelineRow: View {
    let segment: TimelineSegment
    let isFirst: Bool
    let isLast: Bool
    let animatedProgress: Double
    let segmentIndex: Int
    let totalSegments: Int

    private var segmentProgress: Double {
        let threshold = Double(segmentIndex) / Double(totalSegments)
        let segRange = 1.0 / Double(totalSegments)
        return min(1.0, max(0.0, (animatedProgress - threshold) / segRange))
    }

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            VStack(spacing: 0) {
                Circle()
                    .fill(TurbyTurbulenceForecastTheme.turbulenceColor(for: segment.turbulence))
                    .frame(width: 12, height: 12)
                    .scaleEffect(segmentProgress > 0.5 ? 1.0 : 0.5)
                    .opacity(segmentProgress > 0.3 ? 1 : 0.3)
                    .animation(.spring(response: 0.3), value: segmentProgress)

                if !isLast {
                    Rectangle()
                        .fill(TurbyTurbulenceForecastTheme.turbulenceColor(for: segment.turbulence).opacity(0.3))
                        .frame(width: 2)
                        .frame(height: 32)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Image(systemName: segment.phase.icon)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(width: 16)
                    Text(segment.phase.label)
                        .font(.subheadline.weight(.medium))
                    Spacer()
                    Text(segment.turbulence.label)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(TurbyTurbulenceForecastTheme.turbulenceColor(for: segment.turbulence))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(
                            Capsule()
                                .fill(TurbyTurbulenceForecastTheme.turbulenceColor(for: segment.turbulence).opacity(0.12))
                        )
                }

                if segment.turbulence != .smooth {
                    TurbulenceIntensityBar(level: segment.turbulence, animated: segmentProgress > 0.5)
                        .frame(height: 4)
                }
            }
            .padding(.bottom, isLast ? 0 : 8)
        }
        .opacity(segmentProgress > 0.1 ? 1 : 0.4)
        .animation(.easeOut(duration: 0.4), value: segmentProgress)
    }
}

struct TurbulenceIntensityBar: View {
    let level: TurbulenceLevel
    let animated: Bool

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color(.systemGray5))
                Capsule()
                    .fill(TurbyTurbulenceForecastTheme.turbulenceColor(for: level))
                    .frame(width: animated ? geo.size.width * intensityFraction : 0)
                    .animation(.spring(response: 0.5), value: animated)
            }
        }
        .clipShape(Capsule())
    }

    private var intensityFraction: Double {
        switch level {
        case .smooth: 0.15
        case .light: 0.35
        case .moderate: 0.65
        case .severe: 0.9
        }
    }
}
