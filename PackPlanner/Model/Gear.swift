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
        let wt = weight()
        let settings : Settings = SettingsManager.SINGLETON.settings
        let weightUnit = settings.imperial ? "Oz" : "Grams"
        return String(format:"%.2f", wt) + " " + weightUnit
    }
    
//    Given a weight in grams, convert it to oz
    static func convertWeightToImperial(weightInGrams : Double) -> Double {
        return Double(weightInGrams) / Double (conversion)
    }
    
//    Given a weight, format it and return it as a string
    static func getWeightString(weight : Double) -> String {
        let settings : Settings = SettingsManager.SINGLETON.settings
        let wt = settings.imperial ? Gear.convertWeightToImperial(weightInGrams: weight) : weight
        let weightUnit = settings.imperial ? "Oz" : "Grams"
        return String(format:"%.2f", wt) + " " + weightUnit
    }
}
