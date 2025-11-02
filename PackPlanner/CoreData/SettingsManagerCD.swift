//
//  SettingsManagerCD.swift
//  PackPlanner
//
//  Core Data version of SettingsManager
//

import Foundation
import CoreData

class SettingsManagerCD {

    static let SINGLETON = SettingsManagerCD()

    private var context: NSManagedObjectContext {
        return CoreDataStack.shared.viewContext
    }

    var settings: SettingsEntity

    private init() {
        print("SettingsManagerCD initializing...")

        // Initialize settings using explicit context to satisfy Swift's initialization rules
        let coreDataContext = CoreDataStack.shared.viewContext
        self.settings = SettingsEntity.fetchOrCreate(context: coreDataContext)

        print("✅ SettingsManagerCD initialized successfully")
    }

    // MARK: - Helper Methods

    func weightUnitString() -> String {
        return self.settings.imperial ? "(Oz)" : "(Grams)"
    }

    func setFirstTimeUser() {
        self.settings.firstTimeUser = false

        do {
            try context.save()
            print("✅ First time user flag updated")
        } catch {
            print("❌ Error updating first time user: \(error)")
        }
    }

    func toggleUnits() {
        self.settings.imperial.toggle()

        do {
            try context.save()
            print("✅ Units toggled to: \(self.settings.imperial ? "Imperial" : "Metric")")
        } catch {
            print("❌ Error toggling units: \(error)")
            context.rollback()
        }
    }

    /// Save settings to Core Data
    func save() {
        do {
            try context.save()
            print("✅ Settings saved")
        } catch {
            print("❌ Error saving settings: \(error)")
        }
    }

    /// Reload settings from Core Data (refresh after remote changes)
    func reload() {
        context.refreshAllObjects()
        self.settings = SettingsEntity.fetchOrCreate(context: context)
        print("✅ Settings reloaded from Core Data")
    }
}
