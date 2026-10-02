import SwiftUI

public enum BlazeTheme {
    // Brand Backgrounds
    public static let background = Color(hex: "0A111E")
    public static let surface = Color(hex: "111C2E")
    public static let surfaceElevated = Color(hex: "18263E")
    public static let surfaceBorder = Color(hex: "233554")
    
    // Brand Accents
    public static let primary = Color(hex: "1E7BFF")
    public static let primaryGlow = Color(hex: "1E7BFF").opacity(0.3)
    public static let secondary = Color(hex: "4D9AFF")
    
    // Status Colors (Matching BlazeFleet core)
    public static let moving = Color(hex: "2ECC5A")
    public static let idle = Color(hex: "F2A900")
    public static let stopped = Color(hex: "8E9AA8")
    public static let offline = Color(hex: "546375")
    public static let danger = Color(hex: "FF3B30")
    
    // Text Hierarchy
    public static let textPrimary = Color.white
    public static let textSecondary = Color(hex: "94A3B8")
    public static let textMuted = Color(hex: "64748B")
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
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
