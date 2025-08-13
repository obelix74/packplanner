//
//  SettingsManagerSwiftUI.swift
//  PackPlanner
//
//  Created by Claude on SwiftUI Migration
//

import Foundation
import SwiftUI
import RealmSwift
import Combine

class SettingsManagerSwiftUI: ObservableObject {
    static let shared = SettingsManagerSwiftUI()
    
    private let realm: Realm
    @Published var settings: SettingsSwiftUI
    
    private init() {
        do {
            self.realm = try Realm()
            
            // Load existing settings or create default
            let results = realm.objects(Settings.self)
            if let existingSettings = results.first {
                self.settings = SettingsSwiftUI(from: existingSettings)
            } else {
                self.settings = SettingsSwiftUI()
                self.settings.imperial = true
                self.settings.firstTimeUser = true
                saveSettings()
            }
        } catch {
            fatalError("Failed to initialize SettingsManagerSwiftUI: \(error)")
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
        do {
            try realm.write {
                let results = realm.objects(Settings.self)
                if let existingSettings = results.first {
                    existingSettings.imperial = settings.imperial
                    existingSettings.firstTimeUser = settings.firstTimeUser
                } else {
                    let newSettings = settings.toLegacySettings()
                    realm.add(newSettings)
                }
            }
        } catch {
            print("Error saving settings: \(error)")
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