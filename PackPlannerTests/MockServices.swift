//
//  MockServices.swift
//  PackPlannerTests
//
//  Created by Claude on Dependency Injection Testing
//

import Foundation
import XCTest
@testable import PackPlanner

// MARK: - Mock HikeListService

class MockHikeListService: HikeListService {
    typealias SearchableItem = HikeSwiftUI
    
    // Mock data
    var mockHikes: [HikeSwiftUI] = []
    var shouldShowWelcome = false
    var welcomeMessageShown = false
    var deleteCompletionResult = true
    var copyHikeCalled = false
    var deleteHikeCalled = false
    
    func performSearch(items: [HikeSwiftUI], query: String) -> [HikeSwiftUI] {
        if query.isEmpty {
            return items
        }
        return items.filter { hike in
            hike.name.localizedCaseInsensitiveContains(query) ||
            hike.desc.localizedCaseInsensitiveContains(query) ||
            hike.location.localizedCaseInsensitiveContains(query)
        }
    }
    
    func copyHike(_ hike: HikeSwiftUI) {
        copyHikeCalled = true
        // Add copy to mock data
        let copiedHike = HikeSwiftUI()
        copiedHike.name = "Copy of \(hike.name)"
        copiedHike.desc = hike.desc
        copiedHike.location = hike.location
        copiedHike.distance = hike.distance
        mockHikes.append(copiedHike)
    }
    
    func deleteHike(_ hike: HikeSwiftUI, completion: @escaping (Bool) -> Void) {
        deleteHikeCalled = true
        if deleteCompletionResult {
            mockHikes.removeAll { $0.id == hike.id }
        }
        completion(deleteCompletionResult)
    }
    
    func shouldShowWelcomeMessage(hikeCount: Int) -> Bool {
        return shouldShowWelcome
    }
    
    func getWelcomeMessage() -> (title: String, message: String) {
        return (title: "Mock Welcome", message: "Mock message for testing")
    }
    
    func markFirstTimeUserComplete() {
        welcomeMessageShown = true
    }
}

// MARK: - Mock GearListService

class MockGearListService: GearListService {
    typealias SearchableItem = GearSwiftUI
    
    // Mock data
    var mockGears: [GearSwiftUI] = []
    var shouldShowWelcome = false
    var duplicateGearCalled = false
    var deleteGearCalled = false
    var duplicateCompletionResult = true
    var deleteCompletionResult = true
    
    func performSearch(items: [GearSwiftUI], query: String) -> [GearSwiftUI] {
        if query.isEmpty {
            return items
        }
        return items.filter { gear in
            gear.name.localizedCaseInsensitiveContains(query) ||
            gear.desc.localizedCaseInsensitiveContains(query) ||
            gear.category.localizedCaseInsensitiveContains(query)
        }
    }
    
    func groupGearsByCategory(_ gears: [GearSwiftUI]) -> [String: [GearSwiftUI]] {
        return Dictionary(grouping: gears) { $0.category }
    }
    
    func sortedCategories(from groupedGears: [String: [GearSwiftUI]]) -> [String] {
        return groupedGears.keys.sorted()
    }
    
    func duplicateGear(_ gear: GearSwiftUI, completion: @escaping (Bool) -> Void) {
        duplicateGearCalled = true
        if duplicateCompletionResult {
            let duplicatedGear = GearSwiftUI()
            duplicatedGear.name = "\(gear.name) Copy"
            duplicatedGear.desc = gear.desc
            duplicatedGear.category = gear.category
            duplicatedGear.weightInGrams = gear.weightInGrams
            mockGears.append(duplicatedGear)
        }
        completion(duplicateCompletionResult)
    }
    
    func deleteGear(_ gear: GearSwiftUI, completion: @escaping (Bool) -> Void) {
        deleteGearCalled = true
        if deleteCompletionResult {
            mockGears.removeAll { $0.id == gear.id }
        }
        completion(deleteCompletionResult)
    }
    
    func shouldShowWelcomeMessage(gearCount: Int) -> Bool {
        return shouldShowWelcome
    }
    
    func getWelcomeMessage() -> (title: String, message: String) {
        return (title: "Mock No Gear", message: "Mock gear message for testing")
    }
}

// MARK: - Mock AlertService

class MockAlertService: AlertService {
    var deleteAlertCreated = false
    var welcomeAlertCreated = false
    var lastDeleteItemName: String?
    var lastWelcomeTitle: String?
    var lastWelcomeMessage: String?
    
    func createDeleteConfirmationAlert(
        itemName: String,
        onConfirm: @escaping () -> Void,
        onCancel: @escaping () -> Void
    ) -> UIAlertController {
        deleteAlertCreated = true
        lastDeleteItemName = itemName
        
        // Create a real alert for testing
        let alert = UIAlertController(
            title: "Delete \(itemName)",
            message: "Are you sure you want to delete this \(itemName.lowercased())? This action cannot be undone.",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { _ in
            onConfirm()
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in
            onCancel()
        })
        
        return alert
    }
    
    func createWelcomeAlert(title: String, message: String) -> UIAlertController {
        welcomeAlertCreated = true
        lastWelcomeTitle = title
        lastWelcomeMessage = message
        
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Dismiss", style: .default))
        return alert
    }
}

// MARK: - Mock ExportService

class MockExportService: ExportService {
    var exportHikeCalled = false
    var lastExportedHike: Hike?
    var lastPresenter: UIViewController?
    
    func exportHike(_ hike: Hike, presenter: UIViewController) {
        exportHikeCalled = true
        lastExportedHike = hike
        lastPresenter = presenter
        
        // For testing, we don't actually create files or present UI
        print("Mock: Exported hike '\(hike.name)' via presenter")
    }
}

// MARK: - Mock DataService

class MockDataService: DataServiceProtocol {
    var gears: [GearSwiftUI] = []
    var hikes: [HikeSwiftUI] = []
    
    // Track method calls for testing
    var loadDataCalled = false
    var addGearCalled = false
    var updateGearCalled = false
    var deleteGearCalled = false
    var addHikeCalled = false
    var updateHikeCalled = false
    var deleteHikeCalled = false
    
    func loadData() {
        loadDataCalled = true
    }
    
    func addGear(_ gear: GearSwiftUI) {
        addGearCalled = true
        gears.append(gear)
    }
    
    func updateGear(_ gear: GearSwiftUI) {
        updateGearCalled = true
        if let index = gears.firstIndex(where: { $0.id == gear.id }) {
            gears[index] = gear
        }
    }
    
    func deleteGear(_ gear: GearSwiftUI) {
        deleteGearCalled = true
        gears.removeAll { $0.id == gear.id }
    }
    
    func addHike(_ hike: HikeSwiftUI) {
        addHikeCalled = true
        hikes.append(hike)
    }
    
    func updateHike(_ hike: HikeSwiftUI, originalName: String?) {
        updateHikeCalled = true
        if let index = hikes.firstIndex(where: { $0.id == hike.id }) {
            hikes[index] = hike
        }
    }
    
    func deleteHike(_ hike: HikeSwiftUI) {
        deleteHikeCalled = true
        hikes.removeAll { $0.id == hike.id }
    }
    
    func searchGear(query: String) -> [GearSwiftUI] {
        if query.isEmpty {
            return gears
        }
        return gears.filter { gear in
            gear.name.localizedCaseInsensitiveContains(query) ||
            gear.desc.localizedCaseInsensitiveContains(query) ||
            gear.category.localizedCaseInsensitiveContains(query)
        }
    }
    
    func searchHikes(query: String) -> [HikeSwiftUI] {
        if query.isEmpty {
            return hikes
        }
        return hikes.filter { hike in
            hike.name.localizedCaseInsensitiveContains(query) ||
            hike.desc.localizedCaseInsensitiveContains(query) ||
            hike.location.localizedCaseInsensitiveContains(query)
        }
    }
    
    func gearByCategory() -> [String: [GearSwiftUI]] {
        return Dictionary(grouping: gears) { $0.category }
    }
    
    func copyHike(_ originalHike: HikeSwiftUI) -> HikeSwiftUI {
        let copiedHike = HikeSwiftUI()
        copiedHike.name = "Copy of \(originalHike.name)"
        copiedHike.desc = originalHike.desc
        copiedHike.distance = originalHike.distance
        copiedHike.location = originalHike.location
        copiedHike.completed = false
        copiedHike.externalLink1 = originalHike.externalLink1
        copiedHike.externalLink2 = originalHike.externalLink2
        copiedHike.externalLink3 = originalHike.externalLink3
        
        // Copy gear associations
        copiedHike.hikeGears = originalHike.hikeGears.map { originalHikeGear in
            let copiedHikeGear = HikeGearSwiftUI()
            copiedHikeGear.gear = originalHikeGear.gear
            copiedHikeGear.consumable = originalHikeGear.consumable
            copiedHikeGear.worn = originalHikeGear.worn
            copiedHikeGear.numberUnits = originalHikeGear.numberUnits
            copiedHikeGear.verified = false // Reset verification status
            copiedHikeGear.notes = originalHikeGear.notes
            return copiedHikeGear
        }
        
        return copiedHike
    }
    
    func cleanupDatabaseDuplicates() {
        // Mock implementation - no actual cleanup needed
    }
    
    func cleanupDuplicateHikeGears() {
        // Mock implementation - no actual cleanup needed
    }
}

// MARK: - Test Helper for Dependency Injection

class DITestHelper {
    static func setupMockContainer() -> DependencyContainer {
        let container = DependencyContainer.shared
        
        // Clear existing registrations
        container.clearSingletonInstances()
        
        // Register mock services
        container.registerSingleton(HikeListService.self) {
            return MockHikeListService()
        }
        
        container.registerSingleton(GearListService.self) {
            return MockGearListService()
        }
        
        container.registerSingleton(AlertService.self) {
            return MockAlertService()
        }
        
        container.registerSingleton(ExportService.self) {
            return MockExportService()
        }
        
        container.registerSingleton(DataServiceProtocol.self) {
            return MockDataService()
        }
        
        return container
    }
    
    static func resetToProductionContainer() {
        let container = DependencyContainer.shared
        container.clearSingletonInstances()
        
        // Re-register production services
        container.registerSingleton(HikeListService.self) {
            return HikeListLogic.shared
        }
        
        container.registerSingleton(GearListService.self) {
            return GearListLogic.shared
        }
        
        container.registerSingleton(AlertService.self) {
            return AlertLogic.shared
        }
        
        container.registerSingleton(ExportService.self) {
            return ExportLogic.shared
        }
        
        container.registerSingleton(DataServiceProtocol.self) {
            return DataService.shared
        }
    }
}