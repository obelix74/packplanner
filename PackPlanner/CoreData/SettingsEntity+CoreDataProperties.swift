//
//  SettingsEntity+CoreDataProperties.swift
//  PackPlanner
//
//  Created for Core Data + CloudKit Migration
//

import Foundation
import CoreData

extension SettingsEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<SettingsEntity> {
        return NSFetchRequest<SettingsEntity>(entityName: "SettingsEntity")
    }

    @NSManaged public var imperial: Bool
    @NSManaged public var firstTimeUser: Bool

}

extension SettingsEntity: Identifiable {
    // Swift 5.5+ provides automatic Identifiable conformance using objectID
}
