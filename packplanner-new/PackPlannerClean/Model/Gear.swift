//
//  Gear.swift
//  PackPlanner
//
//  Created by Kumar on 9/20/20.
//

import Foundation
import RealmSwift

class Gear : Object {
    @objc dynamic var name : String = ""
    @objc dynamic var desc: String = ""
    @objc dynamic var weightInGrams : Double = 0.0
    @objc dynamic var category: String = "Unknown"
    @objc dynamic var uuid : String = ""
    var hikeGear = LinkingObjects(fromType: HikeGear.self, property: "gearList")
    
    static let conversion : Double = 28.34952
    
    func setValues(name:String, desc: String, weight: Double, category: String)  {
        self.name = name
        self.desc = desc
        if (SettingsManager.SINGLETON.settings.imperial) {
            self.weightInGrams = weight * Gear.conversion
        } else {
            self.weightInGrams = weight
        }
        self.category = category
        self.uuid = UUID().uuidString
    }
    
//    Returns weight based on settings
    func weight() -> Double {
        if (SettingsManager.SINGLETON.settings.imperial) {
            return self.weightInGrams / Gear.conversion
        } else {
            return self.weightInGrams
        }
    }
    
//    Returns weight based on settings with weight unit
    func weightString() -> String {
        return Gear.getWeightString(weight: weightInGrams)
    }
    
//    Given a weight in grams, convert it to oz
    static func convertWeightToImperial(weightInGrams : Double) -> Double {
        return Double(weightInGrams) / Double (conversion)
    }
    
//    Given a weight, format it and return it as a string
    static func getWeightString(weight : Double) -> String {
        let settings : Settings = SettingsManager.SINGLETON.settings
        
        let weightUnit = WeightUnit(weight, settings.imperial)
        let minor = weightUnit.minor
        let minorString = String(format:"%.1f", minor)
        return String("\(weightUnit.major) \(weightUnit.majorUnit) \(minorString) \(weightUnit.minorUnit)")
    }
}

struct WeightUnit {
    var major: Int
    var minor: Double
    var majorUnit: String
    var minorUnit: String
    
    init(_ weightInGrams: Double, _ imperial: Bool) {
        if (imperial) {
            self.majorUnit = "Lb"
            self.minorUnit = "Oz"
            let weightInImperial = Gear.convertWeightToImperial(weightInGrams: weightInGrams)
            self.minor = weightInImperial.truncatingRemainder(dividingBy: 16)
            self.major = Int((weightInImperial / 16).rounded(.towardZero))
        }
        else {
            self.majorUnit = "Kg"
            self.minorUnit = "Grams"
            self.minor = weightInGrams.truncatingRemainder(dividingBy: 1000)
            self.major = Int((weightInGrams / 1000).rounded(.towardZero))
        }
    }
}
