//
//  HikeGearEntity+CoreDataClass.swift
//  PackPlanner
//
//  Created for Core Data + CloudKit Migration
//

import Foundation
import CoreData

@objc(HikeGearEntity)
public class HikeGearEntity: NSManagedObject {

    // MARK: - Convenience Initializer

    convenience init(context: NSManagedObjectContext, gear: GearEntity, hike: HikeEntity, numberUnits: Int = 1) {
        self.init(context: context)
        self.gear = gear
        self.hike = hike
        self.numberUnits = Int32(numberUnits)
        self.consumable = false
        self.worn = false
        self.verified = false
        self.notes = ""
    }

    // MARK: - Helper Methods

    /// Calculate total weight for this gear item (gear weight * quantity)
    func totalWeight(imperial: Bool) -> Double {
        guard let gear = gear else { return 0.0 }
        let singleWeight = gear.weight(imperial: imperial)
        return singleWeight * Double(numberUnits)
    }

    /// Calculate total weight in grams (for calculations)
    func totalWeightInGrams() -> Double {
        guard let gear = gear else { return 0.0 }
        return gear.weightInGrams * Double(numberUnits)
    }

    /// Formatted weight string
    func totalWeightString(imperial: Bool) -> String {
        guard let gear = gear else { return "0" }
        let totalGrams = gear.weightInGrams * Double(numberUnits)
        return GearEntity.getWeightString(weight: totalGrams, imperial: imperial)
    }

    /// Returns gear name safely
    var gearName: String {
        return gear?.name ?? "Unknown Gear"
    }

    /// Returns gear category safely
    var gearCategory: String {
        return gear?.category ?? "Unknown"
    }
}
