//
//  HikeEntity+CoreDataClass.swift
//  PackPlanner
//
//  Created for Core Data + CloudKit Migration
//

import Foundation
import CoreData

@objc(HikeEntity)
public class HikeEntity: NSManagedObject {

    // MARK: - Convenience Initializer

    convenience init(context: NSManagedObjectContext, name: String, desc: String, distance: String, location: String) {
        self.init(context: context)
        self.uuid = UUID().uuidString
        self.name = name
        self.desc = desc
        self.distance = distance
        self.location = location
        self.completed = false
    }

    // MARK: - Helper Methods

    /// Returns all HikeGear items as an array (sorted if needed)
    func hikeGearsArray() -> [HikeGearEntity] {
        let set = hikeGears as? Set<HikeGearEntity> ?? []
        return set.sorted { ($0.gear?.name ?? "") < ($1.gear?.name ?? "") }
    }

    /// Add a HikeGear item to this hike
    func addHikeGear(_ hikeGear: HikeGearEntity) {
        self.addToHikeGears(hikeGear)
    }

    /// Remove a HikeGear item from this hike
    func removeHikeGear(_ hikeGear: HikeGearEntity) {
        self.removeFromHikeGears(hikeGear)
    }

    /// Returns count of gear items
    var gearCount: Int {
        return hikeGears?.count ?? 0
    }

    /// Backfill UUIDs for existing records that don't have one
    static func backfillUUIDs(context: NSManagedObjectContext) {
        let fetchRequest: NSFetchRequest<HikeEntity> = HikeEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "uuid == nil OR uuid == %@", "")

        do {
            let results = try context.fetch(fetchRequest)
            guard !results.isEmpty else { return }

            for hike in results {
                hike.uuid = UUID().uuidString
            }
            try context.save()
        } catch {
            // Backfill is best-effort; errors are non-fatal
        }
    }
}
