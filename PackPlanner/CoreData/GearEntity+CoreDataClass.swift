//
//  GearEntity+CoreDataClass.swift
//  PackPlanner
//
//  Created for Core Data + CloudKit Migration
//

import Foundation
import CoreData

@objc(GearEntity)
public class GearEntity: NSManagedObject {

    static let conversion: Double = 28.34952

    // MARK: - Convenience Initializer

    convenience init(context: NSManagedObjectContext, name: String, desc: String, weight: Double, category: String, imperial: Bool) {
        self.init(context: context)
        self.uuid = UUID().uuidString
        self.setValues(name: name, desc: desc, weight: weight, category: category, imperial: imperial)
    }

    // MARK: - Set Values

    func setValues(name: String, desc: String, weight: Double, category: String, imperial: Bool) {
        self.name = name
        self.desc = desc
        if imperial {
            self.weightInGrams = weight * GearEntity.conversion
        } else {
            self.weightInGrams = weight
        }
        self.category = category

        // Only set UUID if it's not already set (for existing objects)
        if self.uuid?.isEmpty ?? true {
            self.uuid = UUID().uuidString
        }
    }

    // MARK: - Weight Calculations

    /// Returns weight based on imperial/metric setting
    func weight(imperial: Bool) -> Double {
        if imperial {
            return self.weightInGrams / GearEntity.conversion
        } else {
            return self.weightInGrams
        }
    }

    /// Returns formatted weight string with units
    func weightString(imperial: Bool) -> String {
        return GearEntity.getWeightString(weight: self.weightInGrams, imperial: imperial)
    }

    /// Converts weight in grams to ounces
    static func convertWeightToImperial(weightInGrams: Double) -> Double {
        return weightInGrams / conversion
    }

    /// Formats weight and returns as string with units
    static func getWeightString(weight: Double, imperial: Bool) -> String {
        let weightUnit = WeightUnit(weight, imperial)
        let minor = weightUnit.minor
        let minorString = String(format: "%.1f", minor)
        return "\(weightUnit.major) \(weightUnit.majorUnit) \(minorString) \(weightUnit.minorUnit)"
    }
}
