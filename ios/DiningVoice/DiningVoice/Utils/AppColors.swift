import SwiftUI

enum AppColors {
    static let primary = Color(hex: "9333ea")
    static let primaryLight = Color(hex: "c084fc")
    static let primaryDark = Color(hex: "7e22ce")
    static let secondary = Color(hex: "3b82f6")
    static let secondaryLight = Color(hex: "93c5fd")

    static let positive = Color(hex: "10b981")
    static let neutral = Color(hex: "6b7280")
    static let negative = Color(hex: "ef4444")
    static let mixed = Color(hex: "f59e0b")

    static let backgroundLight = Color(hex: "f9fafb")
    static let backgroundDark = Color(hex: "111827")
    static let surfaceLight = Color.white
    static let surfaceDark = Color(hex: "1f2937")

    static let textPrimary = Color(hex: "111827")
    static let textSecondary = Color(hex: "6b7280")

    static func sentimentColor(_ sentiment: SentimentType) -> Color {
        switch sentiment {
        case .positive: return positive
        case .neutral: return neutral
        case .negative: return negative
        case .mixed: return mixed
        }
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
