//
//  GearHelper.swift
//  PackPlanner
//
//  Created by Kumar on 9/24/20.
//

import Foundation
import RealmSwift

class GearBrain {
    private static var _realm: Realm?
    static var realm: Realm {
        if let existingRealm = _realm {
            return existingRealm
        }
        
        do {
            // Use the default configuration that should already be set by SettingsManager
            let newRealm = try Realm()
            _realm = newRealm
            return newRealm
        } catch {
            print("Critical: Failed to initialize Realm database: \(error)")
            // Attempt fallback to in-memory realm
            do {
                let fallbackConfig = Realm.Configuration(
                    inMemoryIdentifier: "gearbrain_fallback",
                    schemaVersion: 1
                )
                let fallbackRealm = try Realm(configuration: fallbackConfig)
                print("GearBrain using in-memory database fallback")
                _realm = fallbackRealm
                return fallbackRealm
            } catch {
                print("Critical: GearBrain fallback Realm initialization failed: \(error)")
                // Create an empty in-memory realm as last resort
                let emptyConfig = Realm.Configuration(
                    inMemoryIdentifier: "gearbrain_emergency_\(UUID().uuidString)",
                    schemaVersion: 1
                )
                do {
                    let emergencyRealm = try Realm(configuration: emptyConfig)
                    print("GearBrain using emergency empty database")
                    _realm = emergencyRealm
                    return emergencyRealm
                } catch {
                    // If even this fails, we can't continue - but let's not crash
                    // Instead, we'll throw an error that can be caught
                    preconditionFailure("Critical: Cannot initialize any database. Please restart the app.")
                }
            }
        }
    }
    
    var gears : [Gear]
    var categoryMap : [String: [Gear]] = [:]
    var categoriesSorted : [String]?
    lazy var settings : Settings = SettingsManager.SINGLETON.settings
    
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
    
    //    Clean up duplicate gear objects in database
    static func cleanupDuplicateGears() {
        do {
            try GearBrain.realm.write {
                let allGears = GearBrain.realm.objects(Gear.self)
                var seenUUIDs = Set<String>()
                var duplicatesToDelete: [Gear] = []
                
                for gear in allGears {
                    if seenUUIDs.contains(gear.uuid) {
                        duplicatesToDelete.append(gear)
                    } else {
                        seenUUIDs.insert(gear.uuid)
                    }
                }
                
                // Delete the duplicates
                for duplicate in duplicatesToDelete {
                    GearBrain.realm.delete(duplicate)
                }
            }
        } catch {
            // Silent error handling - cleanup is best effort
        }
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
            if let gear = hikeGear.gear {
                existingGears.append(gear.uuid)
            }
        }
        let allGears : Results<Gear> = GearBrain.realm.objects(Gear.self)
        var gearList : [Gear] = []
        allGears.forEach { (gear) in
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
                newGear.uuid = UUID().uuidString // Generate new UUID for copy
                newGear.weightInGrams = gear.weightInGrams
                GearBrain.realm.add(newGear)
            }
        } catch {
            print("Error copying gear \(error)")
        }
    }
}
