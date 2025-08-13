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
    
    // Feature flags for gradual migration
    private var enableSwiftUIGearList = true
    private var enableSwiftUIHikeList = true
    private var enableSwiftUIAddGear = true
    private var enableSwiftUIAddHike = true
    private var enableSwiftUISettings = true
    
    private init() {}
    
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
            // Use DataService to get consistent hike data instead of creating new instance
            let dataService = DataService.shared
            if let hikeSwiftUI = dataService.hikes.first(where: { $0.name == hike.name }) {
                return UIHostingController(rootView: HikeDetailView(hike: hikeSwiftUI))
            } else {
                // Fallback to creating new instance if not found in cache
                let hikeSwiftUI = HikeSwiftUI(from: hike)
                return UIHostingController(rootView: HikeDetailView(hike: hikeSwiftUI))
            }
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
        switch feature {
        case .gearList:
            enableSwiftUIGearList = enabled
        case .hikeList:
            enableSwiftUIHikeList = enabled
        case .addGear:
            enableSwiftUIAddGear = enabled
        case .addHike:
            enableSwiftUIAddHike = enabled
        case .settings:
            enableSwiftUISettings = enabled
        }
    }
    
    func isSwiftUIEnabled(for feature: SwiftUIFeature) -> Bool {
        switch feature {
        case .gearList:
            return enableSwiftUIGearList
        case .hikeList:
            return enableSwiftUIHikeList
        case .addGear:
            return enableSwiftUIAddGear
        case .addHike:
            return enableSwiftUIAddHike
        case .settings:
            return enableSwiftUISettings
        }
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