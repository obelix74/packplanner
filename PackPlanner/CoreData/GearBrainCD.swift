//
//  GearBrainCD.swift
//  PackPlanner
//
//  Core Data version of GearBrain
//

import Foundation
import CoreData

class GearBrainCD {

    private var context: NSManagedObjectContext {
        return CoreDataStack.shared.viewContext
    }

    var gears: [GearEntity]
    var categoryMap: [String: [GearEntity]] = [:]
    var categoriesSorted: [String]?
    var settings: SettingsEntity

    init(_ gearList: [GearEntity]) {
        self.gears = gearList
        self.categoryMap = [:]
        // Initialize settings first to satisfy Swift's initialization rules
        let coreDataContext = CoreDataStack.shared.viewContext
        self.settings = SettingsEntity.fetchOrCreate(context: coreDataContext)

        // Now we can use self in closures
        self.gears.forEach { gear in
            var gearArray = self.categoryMap[gear.category]
            if gearArray == nil {
                gearArray = []
            }
            gearArray!.append(gear)
            self.categoryMap[gear.category] = gearArray
        }
        self.categoriesSorted = self.categoryMap.keys.sorted()
    }

    // MARK: - Static Methods

    /// Clean up duplicate gear objects in database
    static func cleanupDuplicateGears() {
        let context = CoreDataStack.shared.viewContext
        let fetchRequest: NSFetchRequest<GearEntity> = GearEntity.fetchRequest()

        do {
            let allGears = try context.fetch(fetchRequest)
            var seenUUIDs = Set<String>()
            var duplicatesToDelete: [GearEntity] = []

            for gear in allGears {
                if let uuid = gear.uuid {
                    if seenUUIDs.contains(uuid) {
                        duplicatesToDelete.append(gear)
                    } else {
                        seenUUIDs.insert(uuid)
                    }
                }
            }

            // Delete duplicates
            for duplicate in duplicatesToDelete {
                context.delete(duplicate)
            }

            if !duplicatesToDelete.isEmpty {
                try context.save()
                print("✅ Cleaned up \(duplicatesToDelete.count) duplicate gears")
            }
        } catch {
            print("❌ Error cleaning up duplicates: \(error)")
        }
    }

    /// Returns gears filtered by an optional search string
    static func getFilteredGears(search: String) -> GearBrainCD {
        let context = CoreDataStack.shared.viewContext
        let fetchRequest: NSFetchRequest<GearEntity> = GearEntity.fetchRequest()

        if !search.isEmpty {
            fetchRequest.predicate = NSPredicate(format: "name CONTAINS[cd] %@", search)
        }
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]

        do {
            let gears = try context.fetch(fetchRequest)
            return GearBrainCD(gears)
        } catch {
            print("❌ Error fetching filtered gears: \(error)")
            return GearBrainCD([])
        }
    }

    /// Given a hike, return only gears not already added to the hike
    static func getFilteredGearsForExistingHike(hike: HikeEntity) -> GearBrainCD {
        let context = CoreDataStack.shared.viewContext

        // Get UUIDs of existing gears in the hike
        var existingGearUUIDs: [String] = []
        if let hikeGears = hike.hikeGears as? Set<HikeGearEntity> {
            for hikeGear in hikeGears {
                if let uuid = hikeGear.gear?.uuid {
                    existingGearUUIDs.append(uuid)
                }
            }
        }

        // Fetch all gears
        let fetchRequest: NSFetchRequest<GearEntity> = GearEntity.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]

        do {
            let allGears = try context.fetch(fetchRequest)

            // Filter out gears already in hike
            let filteredGears = allGears.filter { gear in
                guard let uuid = gear.uuid else { return false }
                return !existingGearUUIDs.contains(uuid)
            }

            return GearBrainCD(filteredGears)
        } catch {
            print("❌ Error fetching gears for hike: \(error)")
            return GearBrainCD([])
        }
    }

    /// Copy a gear item
    static func copyGear(gear: GearEntity) {
        let context = CoreDataStack.shared.viewContext

        let newGear = GearEntity(context: context)
        newGear.category = gear.category
        newGear.desc = gear.desc
        newGear.name = "Copy of " + gear.name
        newGear.uuid = UUID().uuidString
        newGear.weightInGrams = gear.weightInGrams

        do {
            try context.save()
            print("✅ Gear copied successfully")
        } catch {
            print("❌ Error copying gear: \(error)")
        }
    }

    // MARK: - Instance Methods

    func isEmpty() -> Bool {
        return self.gears.isEmpty
    }

    func getGear(indexPath: IndexPath) -> GearEntity? {
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

    func getGearsForSection(section: Int) -> [GearEntity]? {
        guard let category = getCategory(section: section) else { return nil }
        return self.categoryMap[category]
    }

    func deleteGear(gear: GearEntity) {
        let context = CoreDataStack.shared.viewContext

        // Delete associated HikeGear objects
        if let hikeGears = gear.hikeGears as? Set<HikeGearEntity> {
            for hikeGear in hikeGears {
                context.delete(hikeGear)
            }
        }

        // Delete the gear
        context.delete(gear)

        do {
            try context.save()
            print("✅ Gear deleted successfully")
        } catch {
            print("❌ Error deleting gear: \(error)")
        }
    }

    func deleteGearAt(indexPath: IndexPath) {
        if let gear = getGear(indexPath: indexPath) {
            deleteGear(gear: gear)
        }
    }
}
