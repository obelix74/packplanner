//
//  GearHelper.swift
//  PackPlanner
//
//  Created by Kumar on 9/24/20.
//

import Foundation
import RealmSwift

class GearBrain {
    static let realm = try! Realm()
    var gears : [Gear]
    var categoryMap : [String: [Gear]] = [:]
    var categoriesSorted : [String]?
    let settings : Settings = SettingsManager.SINGLETON.settings
    
    init(_ gearList : [Gear]) {
        self.gears = gearList
        self.categoryMap = [:]
        self.gears.forEach({ (gear) in
            var gearArray = self.categoryMap[gear.category]
            if (gearArray == nil) {
                gearArray = []
            }
            gearArray!.append(gear)
            self.categoryMap[gear.category] = gearArray
        })
        self.categoriesSorted = self.categoryMap.keys.sorted()
    }
    
    //    Returns gears filtered by an optional search string
    static func getFilteredGears(search: String) -> GearBrain {
        var gears = GearBrain.realm.objects(Gear.self)
        if (!search.isEmpty) {
            gears = gears.filter("name CONTAINS[cd] %@", search).sorted(byKeyPath: "name", ascending: true)
        }
        
        var gearList : [Gear] = []
        gears.forEach { (gear) in
            gearList.append(gear)
        }
        let gearBrain = GearBrain(gearList)
        return gearBrain
    }
    
    //    Given a hike, walk through the list of existing gears in a hike and return only the gears that are not added yet
    static func getFilteredGearsForExistingHike(hike: Hike) -> GearBrain {
        var existingGears : [String] = []
        hike.hikeGears.forEach { (hikeGear) in
            if let gear = hikeGear.gearList.first {
                print("In GearBrain existingGears: \(gear.name):\(gear.uuid)")
                existingGears.append(gear.uuid)
            }
        }
        let allGears : Results<Gear> = GearBrain.realm.objects(Gear.self)
        var gearList : [Gear] = []
        allGears.forEach { (gear) in
            print("In GearBrain allGears: \(gear.name):\(gear.uuid)")
            if (!existingGears.contains(gear.uuid)) {
                gearList.append(gear)
            }
        }
        let gearBrain = GearBrain(gearList)
        return gearBrain
    }
    
    func isEmpty() -> Bool {
        return self.gears.isEmpty
    }
    
    func getGear(indexPath: IndexPath) -> Gear? {
        let section = indexPath.section
        let category = self.categoriesSorted?[section]
        if (category != nil) {
            let gearsInSection = self.categoryMap[category!]
            return gearsInSection![indexPath.row]
        }
        return nil
    }
    
    func getCategory(section: Int) -> String? {
        return self.categoriesSorted?[section]
    }
    
    func getGearsForSection(section: Int) -> [Gear]? {
        let category = getCategory(section: section)
        return self.categoryMap[category!]
    }
    
    func deleteGear(gear: Gear) {
        do {
            try GearBrain.realm.write {
                let hikeGears = gear.hikeGear
                hikeGears.forEach { (hikeGear) in
                    GearBrain.realm.delete(hikeGear)
                }
                GearBrain.realm.delete(gear)
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
    
    static func copyGear(gear: Gear) {
        do {
            try GearBrain.realm.write {
                let newGear = Gear()
                newGear.category = gear.category
                newGear.desc = gear.desc
                newGear.name = "Copy of " + gear.name
                newGear.uuid = gear.uuid
                newGear.weightInGrams = gear.weightInGrams
                GearBrain.realm.add(newGear)
            }
        } catch {
            print("Error copying gear \(error)")
        }
    }
}
