//
//  SwiftUIDemo.swift
//  PackPlanner
//
//  Created by Claude on SwiftUI Migration
//

import SwiftUI

struct SwiftUIDemo: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            HikeListView()
                .tabItem {
                    Image(systemName: "mountain.2")
                    Text("Hikes")
                }
                .tag(0)
            
            GearListView()
                .tabItem {
                    Image(systemName: "backpack")
                    Text("Gear")
                }
                .tag(1)
            
            SettingsView()
                .tabItem {
                    Image(systemName: "gear")
                    Text("Settings")
                }
                .tag(2)
        }
        .onAppear {
            // Test integration when view appears
            testSwiftUIIntegration()
        }
    }
    
    private func testSwiftUIIntegration() {
        let testHelper = SwiftUIIntegrationTestHelper.shared
        let success = testHelper.validateSwiftUIIntegration()
        
        if success {
            print("🎉 SwiftUI Integration Test PASSED!")
        } else {
            print("⚠️ SwiftUI Integration Test FAILED!")
        }
        
        // Print migration status
        MigrationStatusTracker.shared.printMigrationStatus()
    }
}

// MARK: - Demo Data Creator

struct SwiftUIDemoDataCreator {
    static func createSampleData() {
        let dataService = DataService.shared
        
        // Create sample gear if none exists
        if dataService.gears.isEmpty {
            createSampleGear()
        }
        
        // Create sample hikes if none exists
        if dataService.hikes.isEmpty {
            createSampleHikes()
        }
    }
    
    private static func createSampleGear() {
        let dataService = DataService.shared
        let settingsManager = SettingsManagerSwiftUI.shared
        
        let sampleGear = [
            GearSwiftUI(name: "Tent", desc: "2-person ultralight tent", weight: 2.5, category: "Shelter", imperial: settingsManager.isImperial),
            GearSwiftUI(name: "Sleeping Bag", desc: "Down sleeping bag rated to 20°F", weight: 1.8, category: "Sleep System", imperial: settingsManager.isImperial),
            GearSwiftUI(name: "Backpack", desc: "65L hiking backpack", weight: 3.2, category: "Backpack", imperial: settingsManager.isImperial),
            GearSwiftUI(name: "Water Filter", desc: "Lightweight water purification", weight: 0.3, category: "Hydration", imperial: settingsManager.isImperial),
            GearSwiftUI(name: "Hiking Boots", desc: "Waterproof hiking boots", weight: 2.1, category: "Footwear", imperial: settingsManager.isImperial)
        ]
        
        for gear in sampleGear {
            dataService.addGear(gear)
        }
    }
    
    private static func createSampleHikes() {
        let dataService = DataService.shared
        
        let sampleHikes = [
            HikeSwiftUI(name: "Mount Washington", desc: "Classic New England peak", distance: "8.5 miles", location: "New Hampshire"),
            HikeSwiftUI(name: "Half Dome", desc: "Iconic Yosemite adventure", distance: "16 miles", location: "California"),
            HikeSwiftUI(name: "Angel's Landing", desc: "Thrilling Zion experience", distance: "5.4 miles", location: "Utah")
        ]
        
        for hike in sampleHikes {
            // Add some gear to each hike
            if let tent = dataService.gears.first(where: { $0.name == "Tent" }) {
                hike.addGear(tent)
            }
            if let sleepingBag = dataService.gears.first(where: { $0.name == "Sleeping Bag" }) {
                hike.addGear(sleepingBag)
            }
            
            dataService.addHike(hike)
        }
    }
}

#Preview {
    SwiftUIDemo()
        .onAppear {
            SwiftUIDemoDataCreator.createSampleData()
        }
}