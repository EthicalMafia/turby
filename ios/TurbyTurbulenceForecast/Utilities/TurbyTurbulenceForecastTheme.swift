import SwiftUI

enum TurbyTurbulenceForecastTheme {
    static let accent = Color(red: 0.25, green: 0.48, blue: 0.85)
    static let accentLight = Color(red: 0.40, green: 0.62, blue: 0.95)

    static let skyGradient = LinearGradient(
        colors: [
            Color(red: 0.12, green: 0.16, blue: 0.30),
            Color(red: 0.18, green: 0.28, blue: 0.52),
            Color(red: 0.22, green: 0.38, blue: 0.68)
        ],
        startPoint: .top, endPoint: .bottom
    )

    static func calmBackground(for colorScheme: ColorScheme) -> some View {
        Group {
            if colorScheme == .dark {
                MeshGradient(width: 3, height: 3, points: [
                    [0, 0], [0.5, 0], [1, 0],
                    [0, 0.5], [0.5, 0.5], [1, 0.5],
                    [0, 1], [0.5, 1], [1, 1]
                ], colors: [
                    Color(red: 0.06, green: 0.07, blue: 0.12),
                    Color(red: 0.08, green: 0.10, blue: 0.18),
                    Color(red: 0.06, green: 0.08, blue: 0.14),
                    Color(red: 0.07, green: 0.09, blue: 0.16),
                    Color(red: 0.09, green: 0.12, blue: 0.22),
                    Color(red: 0.07, green: 0.10, blue: 0.18),
                    Color(red: 0.05, green: 0.06, blue: 0.10),
                    Color(red: 0.07, green: 0.09, blue: 0.15),
                    Color(red: 0.06, green: 0.08, blue: 0.13)
                ])
            } else {
                MeshGradient(width: 3, height: 3, points: [
                    [0, 0], [0.5, 0], [1, 0],
                    [0, 0.5], [0.5, 0.5], [1, 0.5],
                    [0, 1], [0.5, 1], [1, 1]
                ], colors: [
                    Color(red: 0.95, green: 0.97, blue: 1.0),
                    Color(red: 0.92, green: 0.95, blue: 1.0),
                    Color(red: 0.94, green: 0.96, blue: 1.0),
                    Color(red: 0.93, green: 0.96, blue: 1.0),
                    Color(red: 0.90, green: 0.94, blue: 0.99),
                    Color(red: 0.92, green: 0.95, blue: 1.0),
                    Color(red: 0.96, green: 0.97, blue: 1.0),
                    Color(red: 0.93, green: 0.95, blue: 0.99),
                    Color(red: 0.95, green: 0.97, blue: 1.0)
                ])
            }
        }
    }

    static func cardBackground(for colorScheme: ColorScheme) -> some ShapeStyle {
        if colorScheme == .dark {
            return AnyShapeStyle(Color(red: 0.11, green: 0.13, blue: 0.20).opacity(0.85))
        } else {
            return AnyShapeStyle(Color(.systemBackground).opacity(0.92))
        }
    }

    static func cardShadow(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? .black.opacity(0.3) : .black.opacity(0.06)
    }

    static func turbulenceColor(for level: TurbulenceLevel) -> Color {
        switch level {
        case .smooth: Color(red: 0.20, green: 0.78, blue: 0.55)
        case .light: Color(red: 0.95, green: 0.75, blue: 0.20)
        case .moderate: Color(red: 0.95, green: 0.50, blue: 0.20)
        case .severe: Color(red: 0.92, green: 0.28, blue: 0.28)
        }
    }

    static func scoreColor(for score: Int) -> Color {
        switch score {
        case 0...2: Color(red: 0.20, green: 0.78, blue: 0.55)
        case 3...4: Color(red: 0.95, green: 0.75, blue: 0.20)
        case 5...7: Color(red: 0.95, green: 0.50, blue: 0.20)
        default: Color(red: 0.92, green: 0.28, blue: 0.28)
        }
    }

    static func scoreGradient(for score: Int) -> LinearGradient {
        let color = scoreColor(for: score)
        return LinearGradient(
            colors: [color.opacity(0.8), color],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

struct GlassCard: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(colorScheme == .dark
                          ? Color.white.opacity(0.06)
                          : Color(.systemBackground).opacity(0.9))
                    .shadow(color: TurbyTurbulenceForecastTheme.cardShadow(for: colorScheme), radius: 16, y: 6)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .strokeBorder(
                        colorScheme == .dark
                        ? Color.white.opacity(0.08)
                        : Color.white.opacity(0.6),
                        lineWidth: 0.5
                    )
            )
    }
}

extension View {
    func glassCard() -> some View {
        modifier(GlassCard())
    }
}
