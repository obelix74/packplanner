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
    @objc dynamic var consumable: Bool = false
    @objc dynamic var wornOnBody: Bool = false
    
    let conversion : Double = 28.34952
    
    func setValues(name: String, desc: String, weight: Double, category: String, consumable: Bool, wornOnBody: Bool) {
        self.name = name
        self.desc = desc
        if (SettingsManager.SINGLETON.settings.imperial) {
            self.weightInGrams = weight * conversion
        } else {
            self.weightInGrams = weight
        }
        self.category = category
        self.consumable = consumable
        self.wornOnBody = wornOnBody
    }
    
    func weight() -> Double {
        if (SettingsManager.SINGLETON.settings.imperial) {
            return self.weightInGrams / conversion
        } else {
            return self.weightInGrams
        }
    }
}
