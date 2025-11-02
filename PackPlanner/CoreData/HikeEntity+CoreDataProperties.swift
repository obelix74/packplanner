//
//  HikeEntity+CoreDataProperties.swift
//  PackPlanner
//
//  Created for Core Data + CloudKit Migration
//

import Foundation
import CoreData

extension HikeEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<HikeEntity> {
        return NSFetchRequest<HikeEntity>(entityName: "HikeEntity")
    }

    @NSManaged public var name: String
    @NSManaged public var desc: String
    @NSManaged public var distance: String
    @NSManaged public var location: String
    @NSManaged public var completed: Bool
    @NSManaged public var externalLink1: String?
    @NSManaged public var externalLink2: String?
    @NSManaged public var externalLink3: String?
    @NSManaged public var hikeGears: NSSet?

}

// MARK: Generated accessors for hikeGears
extension HikeEntity {

    @objc(addHikeGearsObject:)
    @NSManaged public func addToHikeGears(_ value: HikeGearEntity)

    @objc(removeHikeGearsObject:)
    @NSManaged public func removeFromHikeGears(_ value: HikeGearEntity)

    @objc(addHikeGears:)
    @NSManaged public func addToHikeGears(_ values: NSSet)

    @objc(removeHikeGears:)
    @NSManaged public func removeFromHikeGears(_ values: NSSet)

}

extension HikeEntity: Identifiable {
    // Swift 5.5+ provides automatic Identifiable conformance using objectID
}
