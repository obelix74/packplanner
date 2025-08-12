//
//  HikeGearSwiftUI.swift
//  PackPlanner
//
//  Created by Claude on SwiftUI Migration
//

import Foundation
import SwiftUI
import RealmSwift

@Observable
class HikeGearSwiftUI {
    var id: String = UUID().uuidString
    var gear: GearSwiftUI?
    var consumable: Bool = false
    var worn: Bool = false
    var numberUnits: Int = 1
    var verified: Bool = false
    var notes: String = ""
    
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

// Bridge functions for converting between legacy and modern models
extension HikeGearSwiftUI {
    convenience init(from hikeGear: HikeGear) {
        self.init()
        self.consumable = hikeGear.consumable
        self.worn = hikeGear.worn
        self.numberUnits = hikeGear.numberUnits
        self.verified = hikeGear.verified
        self.notes = hikeGear.notes
        
        // The gear relationship will be set by the parent HikeSwiftUI
    }
    
    func toLegacyHikeGear() -> HikeGear {
        let hikeGear = HikeGear()
        hikeGear.consumable = self.consumable
        hikeGear.worn = self.worn
        hikeGear.numberUnits = self.numberUnits
        hikeGear.verified = self.verified
        hikeGear.notes = self.notes
        
        // Add gear to the list if available
        if let gear = self.gear {
            hikeGear.gearList.append(gear.toLegacyGear())
        }
        
        return hikeGear
    }
}