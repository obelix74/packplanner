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
        initializeHike(hike)
    }
    
    func initializeHike(_ hike: Hike) {
        self.hikeGears = hike.hikeGears
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
    
    func getHikeGearsForSection(section: Int) -> [HikeGear]? {
        let category = getCategory(section: section - 1)
        return self.categoryMap[category!]
    }
    
    func deleteHikeGear(gear: HikeGear) {
        do {
            try HikeBrain.realm.write {
                HikeBrain.realm.delete(gear)
            }
        }catch {
            print("Error deleting hikegear \(error)")
        }
    }
    
    func deleteHikeGearAt(indexPath: IndexPath) {
        if let gear = getHikeGear(indexPath: indexPath) {
            deleteHikeGear(gear: gear)
        }
    }
    
    static func createHikeGear(gear: Gear, hike: Hike) {
        do {
        try GearBrain.realm.write {
            let hikeGear = HikeGear()
            hikeGear.gearList.append(gear)
            realm.add(hikeGear)
            hike.hikeGears.append(hikeGear)
        }
        } catch {
            print("Error adding hikeGear \(error)")
        }
    }
}
