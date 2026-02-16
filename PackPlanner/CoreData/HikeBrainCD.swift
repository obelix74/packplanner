//
//  HikeBrainCD.swift
//  PackPlanner
//
//  Core Data version of HikeBrain
//

import Foundation
import CoreData
import os

class HikeBrainCD {

    private var context: NSManagedObjectContext {
        return CoreDataStack.shared.viewContext
    }

    var hike: HikeEntity
    // Total weight of all gear
    var totalWeightInGrams: Double = 0.0
    var totalWeightDistribution: [String: Double] = [:]

    // Total weight of all consumable gear
    var consumableWeightInGrams: Double = 0.0
    var consumableWeightDistribution: [String: Double] = [:]

    // Weight of items except consumables and worn
    var baseWeightInGrams: Double = 0.0
    var baseWeightDistribution: [String: Double] = [:]

    // Total weight worn on body
    var wornWeightInGrams: Double = 0.0
    var wornWeightDistribution: [String: Double] = [:]

    var hikeGears: [HikeGearEntity] = []
    var categoryMap: [String: [HikeGearEntity]] = [:]
    var categoriesSorted: [String]?

    var pendingOnly: Bool
    var settings: SettingsEntity

    init(_ hike: HikeEntity, _ pendingOnly: Bool) {
        self.hike = hike
        self.pendingOnly = pendingOnly
        // Initialize settings using explicit context to satisfy Swift's initialization rules
        let coreDataContext = CoreDataStack.shared.viewContext
        self.settings = SettingsEntity.fetchOrCreate(context: coreDataContext)
        initializeHike()
    }

    // MARK: - Initialization

    fileprivate func updateCategoryWeight(_ dict: inout [String: Double], _ category: String, _ gearWeight: Double) {
        var totalWeightInCategory = dict[category]
        if totalWeightInCategory == nil {
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
        self.hikeGears = []

        // Get all HikeGear objects for this hike
        let allHikeGears = hike.hikeGearsArray()

        allHikeGears.forEach { hikeGear in
            guard let gear = hikeGear.gear else {
                Logger.coreData.warning("HikeGear has no associated gear")
                return
            }
            let number = hikeGear.numberUnits
            let gearWeight = gear.weightInGrams * Double(number)
            let category = gear.category

            self.totalWeightInGrams += gearWeight
            updateCategoryWeight(&self.totalWeightDistribution, category, gearWeight)

            if hikeGear.worn {
                self.wornWeightInGrams += gearWeight
                updateCategoryWeight(&self.wornWeightDistribution, category, gearWeight)
            }

            if hikeGear.consumable {
                self.consumableWeightInGrams += gearWeight
                updateCategoryWeight(&self.consumableWeightDistribution, category, gearWeight)
            }

            if !hikeGear.worn && !hikeGear.consumable {
                self.baseWeightInGrams += gearWeight
                updateCategoryWeight(&self.baseWeightDistribution, category, gearWeight)
            }
        }

        // Filter for pending only if needed
        if self.pendingOnly {
            self.hikeGears = allHikeGears.filter { !$0.verified }
        } else {
            self.hikeGears = allHikeGears
        }

        // Build category map
        self.hikeGears.forEach { hikeGear in
            guard let gear = hikeGear.gear else {
                Logger.coreData.warning("HikeGear has no associated gear")
                return
            }
            var gearArray = self.categoryMap[gear.category]
            if gearArray == nil {
                gearArray = []
            }
            gearArray!.append(hikeGear)
            self.categoryMap[gear.category] = gearArray
        }
        self.categoriesSorted = self.categoryMap.keys.sorted()
    }

    // MARK: - Weight Methods

    func getTotalWeight() -> String {
        return GearEntity.getWeightString(weight: self.totalWeightInGrams, imperial: settings.imperial)
    }

    func getBaseWeight() -> String {
        return GearEntity.getWeightString(weight: self.baseWeightInGrams, imperial: settings.imperial)
    }

    func getWornWeight() -> String {
        return GearEntity.getWeightString(weight: self.wornWeightInGrams, imperial: settings.imperial)
    }

    func getConsumableWeight() -> String {
        return GearEntity.getWeightString(weight: self.consumableWeightInGrams, imperial: settings.imperial)
    }

    // MARK: - Data Access Methods

    func isEmpty() -> Bool {
        return self.hikeGears.isEmpty
    }

    func getHikeGear(indexPath: IndexPath) -> HikeGearEntity? {
        let section = indexPath.section
        guard let category = self.categoriesSorted?[section] else { return nil }
        guard let gearsInSection = self.categoryMap[category] else { return nil }
        guard indexPath.row < gearsInSection.count else { return nil }
        return gearsInSection[indexPath.row]
    }

    func getCategory(section: Int) -> String? {
        guard let categoriesSorted = categoriesSorted, section < categoriesSorted.count else {
            return nil
        }
        return categoriesSorted[section]
    }

    func getNumberSections() -> Int {
        return self.categoryMap.count
    }

    func getNumberOfRowsInSection(section: Int) -> Int {
        return getHikeGearsForSection(section: section)?.count ?? 0
    }

    func getHikeGearsForSection(section: Int) -> [HikeGearEntity]? {
        guard let category = getCategory(section: section) else { return nil }
        return self.categoryMap[category]
    }

    // MARK: - Modification Methods

    func deleteHikeGearAt(indexPath: IndexPath) {
        guard let hikeGear = getHikeGear(indexPath: indexPath) else { return }

        context.delete(hikeGear)

        do {
            try context.save()
            initializeHike()
            Logger.coreData.info("HikeGear deleted successfully")
        } catch {
            Logger.coreData.error("Error deleting HikeGear: \(error)")
        }
    }

    static func createHikeGear(gear: GearEntity, hike: HikeEntity) {
        let context = CoreDataStack.shared.viewContext

        let hikeGear = HikeGearEntity(context: context, gear: gear, hike: hike)

        do {
            try context.save()
            Logger.coreData.info("HikeGear created successfully")
        } catch {
            Logger.coreData.error("Error creating HikeGear: \(error)")
        }
    }

    func updateWornToggle(hikeGear: HikeGearEntity) {
        hikeGear.worn.toggle()

        do {
            try context.save()
            initializeHike()
            Logger.coreData.info("Worn toggle updated")
        } catch {
            Logger.coreData.error("Error updating worn toggle: \(error)")
            context.rollback()
        }
    }

    func updateConsumableToggle(hikeGear: HikeGearEntity) {
        hikeGear.consumable.toggle()

        do {
            try context.save()
            initializeHike()
            Logger.coreData.info("Consumable toggle updated")
        } catch {
            Logger.coreData.error("Error updating consumable toggle: \(error)")
            context.rollback()
        }
    }

    func setNumber(hikeGear: HikeGearEntity, number: Int) {
        hikeGear.numberUnits = Int32(number)

        do {
            try context.save()
            initializeHike()
            Logger.coreData.info("Number updated")
        } catch {
            Logger.coreData.error("Error updating number: \(error)")
            context.rollback()
        }
    }

    func updateVerifiedToggle(hikeGear: HikeGearEntity) {
        hikeGear.verified.toggle()

        do {
            try context.save()
            initializeHike()
            Logger.coreData.info("Verified toggle updated")
        } catch {
            Logger.coreData.error("Error updating verified toggle: \(error)")
            context.rollback()
        }
    }

    // MARK: - Static Methods

    static func copyHike(hike: HikeEntity) {
        let context = CoreDataStack.shared.viewContext

        let newHike = HikeEntity(context: context)
        newHike.uuid = UUID().uuidString
        newHike.name = "Copy of " + hike.name
        newHike.desc = hike.desc
        newHike.completed = false
        newHike.distance = hike.distance
        newHike.location = hike.location
        newHike.externalLink1 = hike.externalLink1
        newHike.externalLink2 = hike.externalLink2
        newHike.externalLink3 = hike.externalLink3

        // Copy all HikeGear associations
        if let hikeGears = hike.hikeGears as? Set<HikeGearEntity> {
            for hikeGear in hikeGears {
                let newHikeGear = HikeGearEntity(context: context)
                newHikeGear.consumable = hikeGear.consumable
                newHikeGear.gear = hikeGear.gear
                newHikeGear.notes = hikeGear.notes
                newHikeGear.numberUnits = hikeGear.numberUnits
                newHikeGear.verified = hikeGear.verified
                newHikeGear.worn = hikeGear.worn
                newHikeGear.hike = newHike
                newHike.addToHikeGears(newHikeGear)
            }
        }

        do {
            try context.save()
            Logger.coreData.info("Hike copied successfully")
        } catch {
            Logger.coreData.error("Error copying hike: \(error)")
        }
    }
}
