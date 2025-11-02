//
//  SettingsEntity+CoreDataClass.swift
//  PackPlanner
//
//  Created for Core Data + CloudKit Migration
//

import Foundation
import CoreData

@objc(SettingsEntity)
public class SettingsEntity: NSManagedObject {

    // MARK: - Singleton Pattern (Similar to SettingsManager)

    /// Fetch or create the singleton settings object
    static func fetchOrCreate(context: NSManagedObjectContext) -> SettingsEntity {
        let fetchRequest: NSFetchRequest<SettingsEntity> = SettingsEntity.fetchRequest()
        fetchRequest.fetchLimit = 1

        do {
            if let settings = try context.fetch(fetchRequest).first {
                return settings
            } else {
                // Create new settings with defaults
                let settings = SettingsEntity(context: context)
                settings.imperial = true
                settings.firstTimeUser = true
                try context.save()
                return settings
            }
        } catch {
            print("❌ Failed to fetch or create settings: \(error)")
            // Return a new object but don't save (caller should handle)
            let settings = SettingsEntity(context: context)
            settings.imperial = true
            settings.firstTimeUser = true
            return settings
        }
    }

    // MARK: - Convenience Methods

    func toggleUnits() {
        self.imperial.toggle()
    }

    func markOnboardingComplete() {
        self.firstTimeUser = false
    }
}
