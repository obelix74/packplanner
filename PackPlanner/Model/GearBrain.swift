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
    
    func getGear(indexPath: IndexPath) -> Gear? {
        let section = indexPath.section
        let category = self.categoriesSorted?[section]
        if (category != nil) {
            let gearsInSection = self.categoryMap![category!]
            return gearsInSection![indexPath.row]
        }
        return nil
    }
    
    func getCategory(section: Int) -> String? {
        return self.categoriesSorted?[section]
    }
    
    func getGearsForSection(section: Int) -> [Gear]? {
        let category = getCategory(section: section)
        return self.categoryMap![category!]
    }
    
    func deleteGear(gear: Gear) {
        do {
            try self.realm.write {
                self.realm.delete(gear)
            }
        }catch {
            print("Error deleting gear \(error)")
        }
    }
    
    func deleteGearAt(indexPath: IndexPath) {
        if let gear = getGear(indexPath: indexPath) {
            deleteGear(gear: gear)
        }
    }
}
