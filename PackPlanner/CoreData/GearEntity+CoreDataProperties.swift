//
//  GearEntity+CoreDataProperties.swift
//  PackPlanner
//
//  Created for Core Data + CloudKit Migration
//

import Foundation
import CoreData

extension GearEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<GearEntity> {
        return NSFetchRequest<GearEntity>(entityName: "GearEntity")
    }

    @NSManaged public var name: String
    @NSManaged public var desc: String
    @NSManaged public var weightInGrams: Double
    @NSManaged public var category: String
    @NSManaged public var uuid: String?
    @NSManaged public var hikeGears: NSSet?

}

// MARK: Generated accessors for hikeGears
extension GearEntity {

    @objc(addHikeGearsObject:)
    @NSManaged public func addToHikeGears(_ value: HikeGearEntity)

    @objc(removeHikeGearsObject:)
    @NSManaged public func removeFromHikeGears(_ value: HikeGearEntity)

    @objc(addHikeGears:)
    @NSManaged public func addToHikeGears(_ values: NSSet)

    @objc(removeHikeGears:)
    @NSManaged public func removeFromHikeGears(_ values: NSSet)

}

extension GearEntity: Identifiable {
    // Swift 5.5+ provides automatic Identifiable conformance using objectID
}
