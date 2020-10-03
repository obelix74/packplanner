//
//  HikeBrain.swift
//  PackPlanner
//
//  Created by Kumar on 9/25/20.
//

import Foundation
import RealmSwift

class HikeBrain {
    
    static let realm = try! Realm()
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
        
        self.hike.hikeGears.forEach { (hikeGear) in
            let gearList = hikeGear.gearList
            let gear = gearList.first!
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
            let gear = hikeGear.gearList.first!
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
            hikeGear.gearList.append(gear)
            realm.add(hikeGear)
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
}
