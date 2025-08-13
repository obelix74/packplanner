//
//  HikeBrain.swift
//  PackPlanner
//
//  Created by Kumar on 9/25/20.
//

import Foundation
import RealmSwift

class HikeBrain {
    
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
                    inMemoryIdentifier: "hikebrain_fallback",
                    schemaVersion: 1
                )
                let fallbackRealm = try Realm(configuration: fallbackConfig)
                print("HikeBrain using in-memory database fallback")
                _realm = fallbackRealm
                return fallbackRealm
            } catch {
                fatalError("Fatal: HikeBrain cannot initialize any Realm database. App cannot continue: \(error)")
            }
        }
    }
    
    var hike : Hike
//  Total weight of all gear
    var totalWeightInGrams : Double = 0.0
    var totalWeightDistribution : [String:Double] = [:]
    
//  Total weight of all gear except worn
    var consumableWeightInGrams : Double = 0.0
    var consumableWeightDistribution : [String:Double] = [:]
    
//  Weight of items except consumables and worn
    var baseWeightInGrams : Double = 0.0
    var baseWeightDistribution : [String: Double] = [:]
    
//  Total weight worn on body
    var wornWeightInGrams : Double = 0.0
    var wornWeightDistribution : [String: Double] = [:]
    
    var hikeGears : List<HikeGear> = List()
    var categoryMap : [String: [HikeGear]] = [:]
    var categoriesSorted : [String]?

    var pendingOnly : Bool
    
    init (_ hike : Hike, _ pendingOnly : Bool) {
        self.hike = hike
        self.pendingOnly = pendingOnly
        initializeHike()
    }
    
    fileprivate func updateCategoryWeight(_ dict: inout [String : Double], _ category: String, _ gearWeight: Double) {
        var totalWeightInCategory = dict[category]
        if (totalWeightInCategory == nil) {
            totalWeightInCategory = 0.0
        }
        totalWeightInCategory! += gearWeight
        dict[category] = totalWeightInCategory
    }
    
    func initializeHike() {
        self.totalWeightInGrams = 0.0
        self.consumableWeightInGrams = 0.0
        self.baseWeightInGrams = 0.0
        self.wornWeightInGrams = 0.0
        self.categoryMap = [:]
        self.totalWeightDistribution = [:]
        self.baseWeightDistribution = [:]
        self.consumableWeightDistribution = [:]
        self.wornWeightDistribution = [:]
        self.hikeGears = List()
        
        self.hike.hikeGears.forEach { (hikeGear) in
            guard let gear = hikeGear.gear else {
                print("Warning: HikeGear has no associated gear")
                return
            }
            let number = hikeGear.numberUnits
            let gearWeight = Double(gear.weightInGrams) * Double(number)
            
            let category = gear.category
            self.totalWeightInGrams += gearWeight
                    
            updateCategoryWeight(&self.totalWeightDistribution, category, gearWeight)
            
            
            if (hikeGear.worn) {
                self.wornWeightInGrams += gearWeight
                updateCategoryWeight(&self.wornWeightDistribution, category, gearWeight)
            }
            
            if (hikeGear.consumable) {
                self.consumableWeightInGrams += gearWeight
                updateCategoryWeight(&self.consumableWeightDistribution, category, gearWeight)
            }
            
            if (!hikeGear.worn && !hikeGear.consumable) {
                self.baseWeightInGrams += gearWeight
                updateCategoryWeight(&self.baseWeightDistribution, category, gearWeight)
            }
        }
        
        if (self.pendingOnly) {
            self.hike.hikeGears.forEach { (hikeGear) in
                if (!hikeGear.verified) {
                    self.hikeGears.append(hikeGear)
                }
            }
        }
        else {
            // use all gears
            self.hikeGears = self.hike.hikeGears
        }
        
        self.hikeGears.forEach({ (hikeGear) in
            guard let gear = hikeGear.gear else {
                print("Warning: HikeGear has no associated gear")
                return
            }
            var gearArray = self.categoryMap[gear.category]
            if (gearArray == nil) {
                gearArray = []
            }
            gearArray!.append(hikeGear)
            self.categoryMap[gear.category] = gearArray
        })
        self.categoriesSorted = self.categoryMap.keys.sorted()
    }
    
    func deleteHikeGearAt(indexPath: IndexPath) {
        if let hikeGear = getHikeGear(indexPath: indexPath) {
            do {
                try HikeBrain.realm.write {
                    HikeBrain.realm.delete(hikeGear)
                    initializeHike()
                }
            }catch {
                print("Error deleting hike \(error)")
            }
        }
    }
    
    func getTotalWeight() -> String {
        return Gear.getWeightString(weight: self.totalWeightInGrams)
    }
    
    func getBaseWeight() -> String {
        return Gear.getWeightString(weight: self.baseWeightInGrams)
    }
    
    func getWornWeight() -> String {
        return Gear.getWeightString(weight: self.wornWeightInGrams)
    }
    
    func getConsumableWeight() -> String {
        return Gear.getWeightString(weight: self.consumableWeightInGrams)
    }
    
    func isEmpty() -> Bool {
        return self.hikeGears.isEmpty
    }
    
    func getHikeGear(indexPath: IndexPath) -> HikeGear? {
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
    
    func getNumberSections() -> Int {
        return self.categoryMap.count
    }
    
    func getNumberOfRowsInSection(section: Int) -> Int {
        return getHikeGearsForSection(section: section)!.count
    }
    
    func getHikeGearsForSection(section: Int) -> [HikeGear]? {
        let category = getCategory(section: section)
        return self.categoryMap[category!]
    }

    static func createHikeGear(gear: Gear, hike: Hike) {
        do {
        try HikeBrain.realm.write {
            let hikeGear = HikeGear()
            hikeGear.gear = gear
            HikeBrain.realm.add(hikeGear)
            hike.hikeGears.append(hikeGear)
        }
        } catch {
            print("Error adding hikeGear \(error)")
        }
    }
    
    func updateWornToggle(hikeGear: HikeGear) {
        do {
            try HikeBrain.realm.write {
                hikeGear.worn = !hikeGear.worn
                initializeHike()
            }
        } catch {
            print("Error updating hikeGear \(error)")
        }
    }
    
    func updateConsumableToggle(hikeGear: HikeGear) {
        do {
            try HikeBrain.realm.write {
                hikeGear.consumable = !hikeGear.consumable
                initializeHike()
            }
        } catch {
            print("Error updating hikeGear \(error)")
        }
    }
    
    func setNumber(hikeGear: HikeGear, number: Int) {
        do {
            try HikeBrain.realm.write {
                hikeGear.numberUnits = number
                initializeHike()
            }
        } catch {
            print("Error updating hikeGear \(error)")
        }
    }
    
    func updateVerifiedToggle(hikeGear: HikeGear) {
        do {
            try HikeBrain.realm.write {
                hikeGear.verified = !hikeGear.verified
                initializeHike()
            }
        } catch {
            print("Error updating hikeGear \(error)")
        }
    }
    
    static func copyHike(hike: Hike) {
        do {
            try HikeBrain.realm.write {
                let newHike = Hike()
                newHike.name = "Copy of " + hike.name
                newHike.desc = hike.desc
                newHike.completed = false
                newHike.distance = hike.distance
                newHike.location = hike.location
                newHike.externalLink1 = hike.externalLink1
                newHike.externalLink2 = hike.externalLink2
                newHike.externalLink3 = hike.externalLink3
                
                hike.hikeGears.forEach { (hikeGear) in
                    let newHikeGear = HikeGear()
                    newHikeGear.consumable = hikeGear.consumable
                    newHikeGear.gear = hikeGear.gear
                    newHikeGear.notes = hikeGear.notes
                    newHikeGear.numberUnits = hikeGear.numberUnits
                    newHikeGear.verified = hikeGear.verified
                    newHikeGear.worn = hikeGear.worn
                    newHike.hikeGears.append(newHikeGear)
                }
                
                HikeBrain.realm.add(newHike)
            }
        } catch {
            print("Error copying hike \(error)")
        }
    }
}
