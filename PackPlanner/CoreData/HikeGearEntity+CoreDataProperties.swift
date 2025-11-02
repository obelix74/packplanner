//
//  HikeGearEntity+CoreDataProperties.swift
//  PackPlanner
//
//  Created for Core Data + CloudKit Migration
//

import Foundation
import CoreData

extension HikeGearEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<HikeGearEntity> {
        return NSFetchRequest<HikeGearEntity>(entityName: "HikeGearEntity")
    }

    @NSManaged public var consumable: Bool
    @NSManaged public var worn: Bool
    @NSManaged public var numberUnits: Int32
    @NSManaged public var verified: Bool
    @NSManaged public var notes: String
    @NSManaged public var gear: GearEntity?
    @NSManaged public var hike: HikeEntity?

}

extension HikeGearEntity: Identifiable {
    // Swift 5.5+ provides automatic Identifiable conformance using objectID
}
