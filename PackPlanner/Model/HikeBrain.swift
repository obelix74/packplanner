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
    
//  Total weight of all gear except worn
    var unwornWeightInGrams : Double = 0.0
    
//  Weight of items except consumables and worn
    var dryWeightInGrams : Double = 0.0
    
//  Total weight worn on body
    var wornWeightInGrams : Double = 0.0
    
    var hikeGears : List<HikeGear> = List()
    var categoryMap : [String: [HikeGear]] = [:]
    var categoriesSorted : [String]?

    init (_ hike : Hike) {
        self.hike = hike
        initializeHike()
    }
    
    func initializeHike() {
        self.hikeGears = self.hike.hikeGears
        self.totalWeightInGrams = 0.0
        self.unwornWeightInGrams = 0.0
        self.dryWeightInGrams = 0.0
        self.wornWeightInGrams = 0.0
        self.categoryMap = [:]
        
        hikeGears.forEach { (hikeGear) in
            let gearList = hikeGear.gearList
            let gear = gearList.first!
            let number = hikeGear.numberUnits
            let gearWeight = Double(gear.weightInGrams) * Double(number)
            
            self.totalWeightInGrams += gearWeight
            
            if (hikeGear.worn) {
                self.wornWeightInGrams += gearWeight
            }
            else {
                self.unwornWeightInGrams += gearWeight
            }
            
            if (!hikeGear.worn && !hikeGear.consumable) {
                self.dryWeightInGrams += gearWeight
            }
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
    
    func getDryWeight() -> String {
        return Gear.getWeightString(weight: self.dryWeightInGrams)
    }
    
    func getWornWeight() -> String {
        return Gear.getWeightString(weight: self.wornWeightInGrams)
    }
    
    func getUnwornWeight() -> String {
        return Gear.getWeightString(weight: self.unwornWeightInGrams)
    }
    
    func isEmpty() -> Bool {
        return self.hikeGears.isEmpty
    }
    
    func getHikeGear(indexPath: IndexPath) -> HikeGear? {
        let section = indexPath.section - 1
        let category = self.categoriesSorted?[section]
        if (category != nil) {
            let gearsInSection = self.categoryMap[category!]
            return gearsInSection![indexPath.row]
        }
        return nil
    }
    
    func getCategory(section: Int) -> String? {
        return self.categoriesSorted?[section - 1]
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
    
    func incrementNumber(hikeGear: HikeGear) {
        do {
            try HikeBrain.realm.write {
                hikeGear.numberUnits = hikeGear.numberUnits + 1
            }
        } catch {
            print("Error updating hikeGear \(error)")
        }
    }
    
    func decrementNumber(hikeGear: HikeGear) {
        do {
            try HikeBrain.realm.write {
                if (hikeGear.numberUnits > 1) {
                    hikeGear.numberUnits = hikeGear.numberUnits - 1
                }
            }

        } catch {
            print("Error updating hikeGear \(error)")
        }
    }
    
    func updateVerifiedToggle(hikeGear: HikeGear) {
        do {
            try HikeBrain.realm.write {
                hikeGear.verified = !hikeGear.verified
            }
        } catch {
            print("Error updating hikeGear \(error)")
        }
    }
}
