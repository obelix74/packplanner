//
//  HikeGearSwiftUI.swift
//  PackPlanner
//
//  Created by Claude on SwiftUI Migration
//

import Foundation
import SwiftUI
import RealmSwift
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
        
        // Reference existing gear instead of creating new one
        if let gear = self.gear {
            // Find existing gear in Realm by UUID
            do {
                let realm = try Realm()
                if let existingGear = realm.objects(Gear.self).filter("uuid == %@", gear.id).first {
                    hikeGear.gearList.append(existingGear)
                } else {
                    // If gear doesn't exist, create it
                    hikeGear.gearList.append(gear.toLegacyGear())
                }
            } catch {
                // Fallback to creating new gear
                hikeGear.gearList.append(gear.toLegacyGear())
            }
        }
        
        return hikeGear
    }
}