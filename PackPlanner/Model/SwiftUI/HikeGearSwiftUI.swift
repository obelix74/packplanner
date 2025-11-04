//
//  HikeGearSwiftUI.swift
//  PackPlanner
//
//  Created by Claude on SwiftUI Migration
//

import Foundation
import SwiftUI
import Combine

class HikeGearSwiftUI: ObservableObject {
    @Published var id: String = UUID().uuidString
    @Published var gear: GearSwiftUI?
    @Published var consumable: Bool = false
    @Published var worn: Bool = false
    @Published var numberUnits: Int = 1
    @Published var verified: Bool = false
    @Published var notes: String = ""
    
    init() {}
    
    init(gear: GearSwiftUI, quantity: Int = 1) {
        self.gear = gear
        self.numberUnits = quantity
    }
    
    var totalWeight: Double {
        return (gear?.weightInGrams ?? 0) * Double(numberUnits)
    }
    
    func weightString(imperial: Bool) -> String {
        return GearSwiftUI.getWeightString(weight: totalWeight, imperial: imperial)
    }
}

