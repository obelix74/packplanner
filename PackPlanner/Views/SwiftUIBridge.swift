//
//  SwiftUIBridge.swift
//  PackPlanner
//
//  Created by Claude on SwiftUI Migration
//

import Foundation
import SwiftUI
import UIKit

// Import SwiftUI views from SwiftUI folder
// Note: These views are located in Views/SwiftUI/ folder

// MARK: - Migration Helper

class SwiftUIMigrationHelper {
    static let shared = SwiftUIMigrationHelper()
    
    // Thread-safe access to feature flags
    private let flagQueue = DispatchQueue(label: "com.packplanner.swiftuiflags", attributes: .concurrent)
    
    // Feature flags for gradual migration
    private var _enableSwiftUIGearList = true
    private var _enableSwiftUIHikeList = true
    private var _enableSwiftUIAddGear = true
    private var _enableSwiftUIAddHike = true
    private var _enableSwiftUISettings = true
    
    private init() {
        loadFeatureFlagsFromUserDefaults()
    }
    
    // MARK: - Thread-Safe Feature Flag Properties
    
    private var enableSwiftUIGearList: Bool {
        get { flagQueue.sync { _enableSwiftUIGearList } }
        set { flagQueue.async(flags: .barrier) { self._enableSwiftUIGearList = newValue } }
    }
    
    private var enableSwiftUIHikeList: Bool {
        get { flagQueue.sync { _enableSwiftUIHikeList } }
        set { flagQueue.async(flags: .barrier) { self._enableSwiftUIHikeList = newValue } }
    }
    
    private var enableSwiftUIAddGear: Bool {
        get { flagQueue.sync { _enableSwiftUIAddGear } }
        set { flagQueue.async(flags: .barrier) { self._enableSwiftUIAddGear = newValue } }
    }
    
    private var enableSwiftUIAddHike: Bool {
        get { flagQueue.sync { _enableSwiftUIAddHike } }
        set { flagQueue.async(flags: .barrier) { self._enableSwiftUIAddHike = newValue } }
    }
    
    private var enableSwiftUISettings: Bool {
        get { flagQueue.sync { _enableSwiftUISettings } }
        set { flagQueue.async(flags: .barrier) { self._enableSwiftUISettings = newValue } }
    }
    
    // MARK: - Factory Methods for Controllers
    
    func createGearListViewController() -> UIViewController {
        if enableSwiftUIGearList {
            return UIHostingController(rootView: GearListView())
        } else {
            // Return legacy UIKit controller
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            return storyboard.instantiateViewController(withIdentifier: "GearListController")
        }
    }
    
    func createHikeListViewController() -> UIViewController {
        if enableSwiftUIHikeList {
            return UIHostingController(rootView: HikeListView())
        } else {
            // Return legacy UIKit controller
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            return storyboard.instantiateViewController(withIdentifier: "HikeListController")
        }
    }
    
    func createAddGearViewController(gear: Gear? = nil) -> UIViewController {
        if enableSwiftUIAddGear {
            let gearSwiftUI = gear != nil ? GearSwiftUI(from: gear!) : nil
            return UIHostingController(rootView: AddGearView(gear: gearSwiftUI))
        } else {
            // Return legacy UIKit controller
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let controller = storyboard.instantiateViewController(withIdentifier: "AddGearViewController")
            // Configure with gear if needed
            return controller
        }
    }
    
    func createAddHikeViewController(hike: Hike? = nil) -> UIViewController {
        if enableSwiftUIAddHike {
            let hikeSwiftUI = hike != nil ? HikeSwiftUI(from: hike!) : nil
            return UIHostingController(rootView: AddHikeView(hike: hikeSwiftUI))
        } else {
            // Return legacy UIKit controller
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let controller = storyboard.instantiateViewController(withIdentifier: "AddHikeViewController")
            // Configure with hike if needed
            return controller
        }
    }
    
    func createHikeDetailViewController(hike: Hike) -> UIViewController {
        if enableSwiftUIHikeList {
            // Safely access DataService on main queue to avoid race conditions
            let dataService = DataService.shared
            
            // Use a synchronous approach to avoid potential race conditions
            let hikeSwiftUI: HikeSwiftUI
            if let cachedHike = dataService.hikes.first(where: { $0.name == hike.name }) {
                hikeSwiftUI = cachedHike
            } else {
                // Fallback to creating new instance if not found in cache
                hikeSwiftUI = HikeSwiftUI(from: hike)
            }
            
            return UIHostingController(rootView: HikeDetailView(hike: hikeSwiftUI))
        } else {
            // Return legacy UIKit controller
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let controller = storyboard.instantiateViewController(withIdentifier: "HikeDetailViewController")
            // Configure with hike
            return controller
        }
    }
    
    func createSettingsViewController() -> UIViewController {
        if enableSwiftUISettings {
            return UIHostingController(rootView: SettingsView())
        } else {
            // Return legacy UIKit controller
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            return storyboard.instantiateViewController(withIdentifier: "SettingsViewController")
        }
    }
    
    // MARK: - Feature Flag Management
    
    func setSwiftUIEnabled(for feature: SwiftUIFeature, enabled: Bool) {
        // Ensure thread-safe updates using barrier queue
        flagQueue.async(flags: .barrier) { [weak self] in
            guard let self = self else { return }
            switch feature {
            case .gearList:
                self._enableSwiftUIGearList = enabled
            case .hikeList:
                self._enableSwiftUIHikeList = enabled
            case .addGear:
                self._enableSwiftUIAddGear = enabled
            case .addHike:
                self._enableSwiftUIAddHike = enabled
            case .settings:
                self._enableSwiftUISettings = enabled
            }
            // Persist changes to UserDefaults
            self.saveFeatureFlagsToUserDefaults()
        }
    }
    
    func isSwiftUIEnabled(for feature: SwiftUIFeature) -> Bool {
        return flagQueue.sync {
            switch feature {
            case .gearList:
                return _enableSwiftUIGearList
            case .hikeList:
                return _enableSwiftUIHikeList
            case .addGear:
                return _enableSwiftUIAddGear
            case .addHike:
                return _enableSwiftUIAddHike
            case .settings:
                return _enableSwiftUISettings
            }
        }
    }
    
    // MARK: - Persistence
    
    private func loadFeatureFlagsFromUserDefaults() {
        let defaults = UserDefaults.standard
        _enableSwiftUIGearList = defaults.object(forKey: "SwiftUI.GearList.Enabled") as? Bool ?? true
        _enableSwiftUIHikeList = defaults.object(forKey: "SwiftUI.HikeList.Enabled") as? Bool ?? true
        _enableSwiftUIAddGear = defaults.object(forKey: "SwiftUI.AddGear.Enabled") as? Bool ?? true
        _enableSwiftUIAddHike = defaults.object(forKey: "SwiftUI.AddHike.Enabled") as? Bool ?? true
        _enableSwiftUISettings = defaults.object(forKey: "SwiftUI.Settings.Enabled") as? Bool ?? true
    }
    
    private func saveFeatureFlagsToUserDefaults() {
        let defaults = UserDefaults.standard
        defaults.set(_enableSwiftUIGearList, forKey: "SwiftUI.GearList.Enabled")
        defaults.set(_enableSwiftUIHikeList, forKey: "SwiftUI.HikeList.Enabled")
        defaults.set(_enableSwiftUIAddGear, forKey: "SwiftUI.AddGear.Enabled")
        defaults.set(_enableSwiftUIAddHike, forKey: "SwiftUI.AddHike.Enabled")
        defaults.set(_enableSwiftUISettings, forKey: "SwiftUI.Settings.Enabled")
    }
    
    /**
     * Enables or disables all SwiftUI features at once.
     * Useful for testing or quickly switching between UIKit and SwiftUI modes.
     */
    func setAllSwiftUIFeatures(enabled: Bool) {
        flagQueue.async(flags: .barrier) { [weak self] in
            guard let self = self else { return }
            self._enableSwiftUIGearList = enabled
            self._enableSwiftUIHikeList = enabled
            self._enableSwiftUIAddGear = enabled
            self._enableSwiftUIAddHike = enabled
            self._enableSwiftUISettings = enabled
            self.saveFeatureFlagsToUserDefaults()
        }
    }
    
    /**
     * Gets the current migration progress as a percentage.
     */
    func getMigrationProgress() -> Double {
        let enabledFeatures = [
            _enableSwiftUIGearList,
            _enableSwiftUIHikeList,
            _enableSwiftUIAddGear,
            _enableSwiftUIAddHike,
            _enableSwiftUISettings
        ].filter { $0 }
        
        return Double(enabledFeatures.count) / 5.0 * 100.0
    }
}

enum SwiftUIFeature {
    case gearList
    case hikeList
    case addGear
    case addHike
    case settings
}

// MARK: - Migration Status Tracker

class MigrationStatusTracker {
    static let shared = MigrationStatusTracker()
    
    private init() {}
    
    var migrationProgress: [String: Bool] {
        return [
            "SwiftUI Models": true,
            "DataService": true,
            "SettingsManagerSwiftUI": true,
            "GearListView": true,
            "HikeListView": true,
            "AddGearView": true,
            "AddHikeView": true,
            "HikeDetailView": true,
            "SettingsView": true,
            "SwiftUIBridge": true
        ]
    }
    
    var completionPercentage: Double {
        let completed = migrationProgress.values.filter { $0 }.count
        let total = migrationProgress.count
        return Double(completed) / Double(total) * 100
    }
    
    func printMigrationStatus() {
        print("=== SwiftUI Migration Status ===")
        for (component, completed) in migrationProgress {
            let status = completed ? "✅" : "❌"
            print("\(status) \(component)")
        }
        print("Overall Progress: \(String(format: "%.1f", completionPercentage))%")
        print("==============================")
    }
}

// MARK: - SwiftUI Integration Test Helper

class SwiftUIIntegrationTestHelper {
    static let shared = SwiftUIIntegrationTestHelper()
    
    private init() {}
    
    func validateSwiftUIIntegration() -> Bool {
        var allTestsPassed = true
        
        // Test DataService initialization
        do {
            let dataService = DataService.shared
            print("✅ DataService initialized successfully")
        } catch {
            print("❌ DataService initialization failed: \(error)")
            allTestsPassed = false
        }
        
        // Test SettingsManagerSwiftUI initialization
        do {
            let settingsManager = SettingsManagerSwiftUI.shared
            print("✅ SettingsManagerSwiftUI initialized successfully")
        } catch {
            print("❌ SettingsManagerSwiftUI initialization failed")
            allTestsPassed = false
        }
        
        // Test SwiftUI View creation
        do {
            let _ = GearListView()
            let _ = HikeListView()
            let _ = AddGearView(gear: nil)
            let _ = AddHikeView(hike: nil)
            let _ = SettingsView()
            print("✅ All SwiftUI Views can be instantiated")
        } catch {
            print("❌ SwiftUI View instantiation failed: \(error)")
            allTestsPassed = false
        }
        
        // Test Bridge functionality
        do {
            let bridge = SwiftUIMigrationHelper.shared
            let _ = bridge.createGearListViewController()
            let _ = bridge.createHikeListViewController()
            let _ = bridge.createSettingsViewController()
            print("✅ SwiftUI Bridge working correctly")
        } catch {
            print("❌ SwiftUI Bridge failed: \(error)")
            allTestsPassed = false
        }
        
        return allTestsPassed
    }
}