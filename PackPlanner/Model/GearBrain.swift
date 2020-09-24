//
//  GearHelper.swift
//  PackPlanner
//
//  Created by Kumar on 9/24/20.
//

import Foundation
import RealmSwift

class GearBrain {
    let realm = try! Realm()
    var gears : Results<Gear>?
    var categoryMap : [String: [Gear]]? = [:]
    var categoriesSorted : [String]?
    let settings : Settings = SettingsManager.SINGLETON.settings
    
    static func getFilteredGears(search: String) -> GearBrain {
        let gearBrain = GearBrain()
        gearBrain.gears = gearBrain.realm.objects(Gear.self)
        
        if (!search.isEmpty) {
            gearBrain.gears = gearBrain.gears?.filter("name CONTAINS[cd] %@", search).sorted(byKeyPath: "name", ascending: true)
        }
        
        gearBrain.categoryMap = [:]
        gearBrain.gears?.forEach({ (gear) in
            var gearArray = gearBrain.categoryMap?[gear.category]
            if (gearArray == nil) {
                gearArray = []
            }
            gearArray?.append(gear)
            gearBrain.categoryMap?[gear.category] = gearArray
        })
        
        gearBrain.categoriesSorted = gearBrain.categoryMap?.keys.sorted()

        return gearBrain
    }
    
}
