//
//  SettingsManagerSwiftUI.swift
//  PackPlanner
//
//  Created by Claude on SwiftUI Migration
//

import Foundation
import SwiftUI
import Combine
import CoreData
import os

class SettingsManagerSwiftUI: ObservableObject {
    static let shared = SettingsManagerSwiftUI()

    private let context = CoreDataStack.shared.viewContext
    @Published var settings: SettingsSwiftUI

    private init() {
        // Load existing settings from Core Data or create default
        let fetchRequest: NSFetchRequest<SettingsEntity> = SettingsEntity.fetchRequest()

        do {
            let results = try context.fetch(fetchRequest)
            if let existingSettings = results.first {
                self.settings = SettingsSwiftUI(fromCoreData: existingSettings)
            } else {
                self.settings = SettingsSwiftUI()
                self.settings.imperial = true
                self.settings.firstTimeUser = true
                saveSettings()
            }
        } catch {
            Logger.app.error("Error loading settings from Core Data: \(error)")
            // Fallback to defaults
            self.settings = SettingsSwiftUI()
            self.settings.imperial = true
            self.settings.firstTimeUser = true
        }
    }

    func updateImperialSetting(_ imperial: Bool) {
        settings.imperial = imperial
        saveSettings()
    }

    func updateFirstTimeUser(_ firstTime: Bool) {
        settings.firstTimeUser = firstTime
        saveSettings()
    }

    private func saveSettings() {
        let fetchRequest: NSFetchRequest<SettingsEntity> = SettingsEntity.fetchRequest()

        do {
            let results = try context.fetch(fetchRequest)
            let settingsEntity: SettingsEntity

            if let existingSettings = results.first {
                settingsEntity = existingSettings
            } else {
                settingsEntity = SettingsEntity(context: context)
            }

            settingsEntity.imperial = settings.imperial
            settingsEntity.firstTimeUser = settings.firstTimeUser

            try context.save()
        } catch {
            Logger.app.error("Error saving settings to Core Data: \(error)")
        }
    }

    // Convenience computed properties
    var isImperial: Bool {
        get { settings.imperial }
        set { updateImperialSetting(newValue) }
    }

    var isFirstTimeUser: Bool {
        get { settings.firstTimeUser }
        set { updateFirstTimeUser(newValue) }
    }

    var weightUnit: String {
        settings.weightUnit
    }

    var distanceUnit: String {
        settings.distanceUnit
    }

    // Weight conversion utilities
    func formatWeight(_ weightInGrams: Double) -> String {
        return GearSwiftUI.getWeightString(weight: weightInGrams, imperial: settings.imperial)
    }

    func convertWeight(_ weight: Double, fromImperial: Bool) -> Double {
        if fromImperial == settings.imperial {
            return weight
        } else if fromImperial {
            // Converting from imperial to metric
            return weight * GearSwiftUI.conversion
        } else {
            // Converting from metric to imperial
            return weight / GearSwiftUI.conversion
        }
    }
}
