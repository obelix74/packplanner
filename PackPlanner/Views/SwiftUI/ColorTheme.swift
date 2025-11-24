//
//  ColorTheme.swift
//  PackPlanner
//
//  Vibrant color theme for modern hiking app
//

import SwiftUI

extension Color {
    // MARK: - Brand Colors
    static let packPrimary = Color(hex: "4CAF50")      // Vibrant green (hiking/nature)
    static let packSecondary = Color(hex: "2E7D32")    // Deep forest green
    static let packAccent = Color(hex: "FF9800")       // Warm orange (adventure)
    
    // MARK: - Weight Category Colors
    static let totalWeightColor = Color(hex: "5C6BC0")     // Indigo
    static let baseWeightColor = Color(hex: "42A5F5")      // Bright blue
    static let wornWeightColor = Color(hex: "66BB6A")      // Fresh green
    static let consumableColor = Color(hex: "FFA726")      // Warm orange
    
    // MARK: - Status Colors
    static let completedColor = Color(hex: "4CAF50")       // Green
    static let pendingColor = Color(hex: "FF9800")         // Orange
    static let verifiedColor = Color(hex: "2196F3")        // Blue
    
    // MARK: - Category Colors
    static let shelterColor = Color(hex: "E91E63")         // Pink
    static let sleepingColor = Color(hex: "9C27B0")        // Purple
    static let cookingColor = Color(hex: "FF5722")         // Deep orange
    static let clothingColor = Color(hex: "00BCD4")        // Cyan
    static let hygieneColor = Color(hex: "8BC34A")         // Light green
    static let electronicsColor = Color(hex: "FFC107")     // Amber
    static let safetyColor = Color(hex: "F44336")          // Red
    static let miscColor = Color(hex: "9E9E9E")            // Grey
    
    // MARK: - Background Gradients
    static let hikeGradientStart = Color(hex: "4CAF50")
    static let hikeGradientEnd = Color(hex: "81C784")
    
    static let mountainGradientStart = Color(hex: "5C6BC0")
    static let mountainGradientEnd = Color(hex: "9FA8DA")
    
    static let sunsetGradientStart = Color(hex: "FF9800")
    static let sunsetGradientEnd = Color(hex: "FFB74D")
    
    // MARK: - Helper
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
    
    // MARK: - Category Color Helper
    static func categoryColor(for category: String) -> Color {
        switch category.lowercased() {
        case "shelter": return .shelterColor
        case "sleeping": return .sleepingColor
        case "cooking": return .cookingColor
        case "clothing": return .clothingColor
        case "hygiene": return .hygieneColor
        case "electronics": return .electronicsColor
        case "safety", "first aid": return .safetyColor
        default: return .miscColor
        }
    }
}

// MARK: - Gradient Presets
extension LinearGradient {
    static let hikeGradient = LinearGradient(
        colors: [Color.hikeGradientStart, Color.hikeGradientEnd],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let mountainGradient = LinearGradient(
        colors: [Color.mountainGradientStart, Color.mountainGradientEnd],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let sunsetGradient = LinearGradient(
        colors: [Color.sunsetGradientStart, Color.sunsetGradientEnd],
        startPoint: .leading,
        endPoint: .trailing
    )
    
    static let forestGradient = LinearGradient(
        colors: [Color(hex: "2E7D32"), Color(hex: "66BB6A")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

// MARK: - View Modifiers
struct ColorfulCard: ViewModifier {
    let gradient: LinearGradient
    
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(gradient)
                    .shadow(color: .black.opacity(0.15), radius: 10, y: 5)
            )
    }
}

struct GlassmorphicCard: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
                    .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
            )
    }
}

extension View {
    func colorfulCard(_ gradient: LinearGradient = .hikeGradient) -> some View {
        modifier(ColorfulCard(gradient: gradient))
    }
    
    func glassmorphicCard() -> some View {
        modifier(GlassmorphicCard())
    }
}
