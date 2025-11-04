//
//  GearSwiftUI.swift
//  PackPlanner
//
//  Created by Claude on SwiftUI Migration
//

import Foundation
import SwiftUI
import CoreData
import Combine

class GearSwiftUI: ObservableObject, Identifiable {
    @Published var id: String = UUID().uuidString
    @Published var name: String = ""
    @Published var desc: String = ""
    @Published var weightInGrams: Double = 0.0
    @Published var category: String = "Uncategorized"
    @Published var hikeGears: [HikeGearSwiftUI] = []
    
    static let conversion: Double = 28.34952
    
    init() {}
    
    init(name: String, desc: String, weight: Double, category: String, imperial: Bool) {
        self.name = name
        self.desc = desc
        self.category = category
        setWeight(weight: weight, imperial: imperial)
    }
    
    func setWeight(weight: Double, imperial: Bool) {
        if imperial {
            self.weightInGrams = weight * GearSwiftUI.conversion
        } else {
            self.weightInGrams = weight
        }
    }
    
    func weight(imperial: Bool) -> Double {
        if imperial {
            return self.weightInGrams / GearSwiftUI.conversion
        } else {
            return self.weightInGrams
        }
    }
    
    func weightString(imperial: Bool) -> String {
        return GearSwiftUI.getWeightString(weight: weightInGrams, imperial: imperial)
    }
    
    static func convertWeightToImperial(weightInGrams: Double) -> Double {
        return weightInGrams / conversion
    }
    
    static func getWeightString(weight: Double, imperial: Bool) -> String {
        let weightUnit = WeightUnitSwiftUI(weight, imperial)
        let minor = weightUnit.minor
        let minorString = String(format:"%.1f", minor)
        return "\(weightUnit.major) \(weightUnit.majorUnit) \(minorString) \(weightUnit.minorUnit)"
    }
}

struct WeightUnitSwiftUI {
    var major: Int
    var minor: Double
    var majorUnit: String
    var minorUnit: String
    
    init(_ weightInGrams: Double, _ imperial: Bool) {
        if imperial {
            self.majorUnit = "Lb"
            self.minorUnit = "Oz"
            let weightInImperial = GearSwiftUI.convertWeightToImperial(weightInGrams: weightInGrams)
            var minorOz = weightInImperial.truncatingRemainder(dividingBy: 16)
            var majorLb = Int((weightInImperial / 16).rounded(.towardZero))

            // If minor rounds to 16 oz, convert to 1 lb
            if minorOz.rounded() >= 16.0 {
                majorLb += 1
                minorOz = 0.0
            }

            self.minor = minorOz
            self.major = majorLb
        } else {
            self.majorUnit = "Kg"
            self.minorUnit = "Grams"
            self.minor = weightInGrams.truncatingRemainder(dividingBy: 1000)
            self.major = Int((weightInGrams / 1000).rounded(.towardZero))
        }
    }
}

// Bridge functions for Core Data
extension GearSwiftUI {
    convenience init(fromCoreData gear: GearEntity) {
        self.init()
        self.id = gear.uuid ?? UUID().uuidString
        self.name = gear.name
        self.desc = gear.desc
        self.weightInGrams = gear.weightInGrams
        self.category = gear.category
    }
}