//
//  CategoryHelper.swift
//  PackPlanner
//
//  Helper for category icons and colors
//

import SwiftUI

extension String {
    var categoryIcon: String {
        switch self.lowercased() {
        case "shelter": return "tent.fill"
        case "sleeping": return "bed.double.fill"
        case "cooking": return "flame.fill"
        case "clothing": return "tshirt.fill"
        case "hygiene": return "drop.fill"
        case "electronics": return "bolt.fill"
        case "safety", "first aid": return "cross.fill"
        case "water": return "drop.triangle.fill"
        case "food": return "fork.knife"
        case "navigation": return "map.fill"
        case "tools": return "wrench.and.screwdriver.fill"
        default: return "square.grid.2x2.fill"
        }
    }
    
    var categoryColor: Color {
        switch self.lowercased() {
        case "shelter": return .pink
        case "sleeping": return .purple
        case "cooking": return .orange
        case "clothing": return .cyan
        case "hygiene": return .green
        case "electronics": return .yellow
        case "safety", "first aid": return .red
        case "water": return .blue
        case "food": return .brown
        case "navigation": return .indigo
        case "tools": return .gray
        default: return .gray
        }
    }
}
