//
//  SettingsManagerCD.swift
//  PackPlanner
//
//  Core Data version of SettingsManager
//

import Foundation
import CoreData
import os

// Typealias for DependencyContainer compatibility
typealias SettingsManager = SettingsManagerCD

class SettingsManagerCD {

    static let SINGLETON = SettingsManagerCD()

    private var context: NSManagedObjectContext {
        return CoreDataStack.shared.viewContext
    }

    var settings: SettingsEntity

    private init() {
        Logger.coreData.debug("SettingsManagerCD initializing...")

        // Initialize settings using explicit context to satisfy Swift's initialization rules
        let coreDataContext = CoreDataStack.shared.viewContext
        self.settings = SettingsEntity.fetchOrCreate(context: coreDataContext)

        Logger.coreData.info("SettingsManagerCD initialized successfully")
    }

    // MARK: - Helper Methods

    func weightUnitString() -> String {
        return self.settings.imperial ? "(Oz)" : "(Grams)"
    }

    func setFirstTimeUser() {
        self.settings.firstTimeUser = false

        do {
            try context.save()
            Logger.coreData.info("First time user flag updated")
        } catch {
            Logger.coreData.error("Error updating first time user: \(error)")
        }
    }

    func toggleUnits() {
        self.settings.imperial.toggle()

        do {
            try context.save()
            Logger.coreData.info("Units toggled to: \(self.settings.imperial ? "Imperial" : "Metric")")
        } catch {
            Logger.coreData.error("Error toggling units: \(error)")
            context.rollback()
        }
    }

    /// Save settings to Core Data
    func save() {
        do {
            try context.save()
            Logger.coreData.info("Settings saved")
        } catch {
            Logger.coreData.error("Error saving settings: \(error)")
        }
    }

    /// Reload settings from Core Data (refresh after remote changes)
    func reload() {
        context.refreshAllObjects()
        self.settings = SettingsEntity.fetchOrCreate(context: context)
        Logger.coreData.info("Settings reloaded from Core Data")
    }
}
