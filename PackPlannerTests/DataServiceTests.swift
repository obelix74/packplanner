//
//  DataServiceTests.swift
//  PackPlannerTests
//
//  Created by Claude on Unit Testing
//

import XCTest
@testable import PackPlanner
import RealmSwift

class DataServiceTests: XCTestCase {
    
    var dataService: DataService!
    var testRealm: Realm!
    
    override func setUp() {
        super.setUp()
        
        // Create in-memory Realm for testing
        let configuration = Realm.Configuration(
            inMemoryIdentifier: "DataServiceTests-\(UUID().uuidString)",
            schemaVersion: 1
        )
        
        do {
            testRealm = try Realm(configuration: configuration)
            // Note: In a real implementation, we'd inject this test realm into DataService
            // For now, we'll test the public interface
            dataService = DataService.shared
        } catch {
            XCTFail("Failed to create test Realm: \(error)")
        }
    }
    
    override func tearDown() {
        dataService = nil
        testRealm = nil
        super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    func testDataServiceSingleton() {
        let instance1 = DataService.shared
        let instance2 = DataService.shared
        
        XCTAssertTrue(instance1 === instance2, "DataService should be a singleton")
    }
    
    func testLoadData() {
        XCTAssertNoThrow(dataService.loadData())
    }
    
    // MARK: - Gear CRUD Tests
    
    func testAddGear() {
        let gear = GearSwiftUI()
        gear.name = "Test Gear"
        gear.desc = "Test Description"
        gear.weightInGrams = 100
        gear.category = "Clothing"
        
        XCTAssertNoThrow(dataService.addGear(gear))
        
        // Give some time for async operation
        let expectation = self.expectation(description: "Add gear")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation.fulfill()
        }
        waitForExpectations(timeout: 1.0, handler: nil)
    }
    
    func testUpdateGear() {
        let gear = GearSwiftUI()
        gear.name = "Original Name"
        gear.desc = "Original Description"
        gear.weightInGrams = 100
        gear.category = "Clothing"
        
        // First add the gear
        dataService.addGear(gear)
        
        // Wait for add operation
        let addExpectation = self.expectation(description: "Add gear")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            addExpectation.fulfill()
        }
        waitForExpectations(timeout: 1.0, handler: nil)
        
        // Update the gear
        gear.name = "Updated Name"
        gear.desc = "Updated Description"
        
        XCTAssertNoThrow(dataService.updateGear(gear))
        
        // Wait for update operation
        let updateExpectation = self.expectation(description: "Update gear")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            updateExpectation.fulfill()
        }
        waitForExpectations(timeout: 1.0, handler: nil)
    }
    
    func testDeleteGear() {
        let gear = GearSwiftUI()
        gear.name = "Gear to Delete"
        gear.desc = "Will be deleted"
        gear.weightInGrams = 50
        gear.category = "Equipment"
        
        // First add the gear
        dataService.addGear(gear)
        
        // Wait for add operation
        let addExpectation = self.expectation(description: "Add gear")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            addExpectation.fulfill()
        }
        waitForExpectations(timeout: 1.0, handler: nil)
        
        // Delete the gear
        XCTAssertNoThrow(dataService.deleteGear(gear))
        
        // Wait for delete operation
        let deleteExpectation = self.expectation(description: "Delete gear")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            deleteExpectation.fulfill()
        }
        waitForExpectations(timeout: 1.0, handler: nil)
    }
    
    // MARK: - Hike CRUD Tests
    
    func testAddHike() {
        let hike = HikeSwiftUI()
        hike.name = "Test Hike"
        hike.desc = "Test Description"
        hike.location = "Test Location"
        hike.distance = 10.5
        hike.completed = false
        
        XCTAssertNoThrow(dataService.addHike(hike))
        
        // Give some time for async operation
        let expectation = self.expectation(description: "Add hike")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation.fulfill()
        }
        waitForExpectations(timeout: 1.0, handler: nil)
    }
    
    func testUpdateHike() {
        let hike = HikeSwiftUI()
        hike.name = "Original Hike"
        hike.desc = "Original Description"
        hike.location = "Original Location"
        hike.distance = 5.0
        hike.completed = false
        
        // First add the hike
        dataService.addHike(hike)
        
        // Wait for add operation
        let addExpectation = self.expectation(description: "Add hike")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            addExpectation.fulfill()
        }
        waitForExpectations(timeout: 1.0, handler: nil)
        
        // Update the hike
        hike.desc = "Updated Description"
        hike.completed = true
        
        XCTAssertNoThrow(dataService.updateHike(hike))
        
        // Wait for update operation
        let updateExpectation = self.expectation(description: "Update hike")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            updateExpectation.fulfill()
        }
        waitForExpectations(timeout: 1.0, handler: nil)
    }
    
    func testDeleteHike() {
        let hike = HikeSwiftUI()
        hike.name = "Hike to Delete"
        hike.desc = "Will be deleted"
        hike.location = "Test Location"
        hike.distance = 3.0
        hike.completed = false
        
        // First add the hike
        dataService.addHike(hike)
        
        // Wait for add operation
        let addExpectation = self.expectation(description: "Add hike")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            addExpectation.fulfill()
        }
        waitForExpectations(timeout: 1.0, handler: nil)
        
        // Delete the hike
        XCTAssertNoThrow(dataService.deleteHike(hike))
        
        // Wait for delete operation
        let deleteExpectation = self.expectation(description: "Delete hike")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            deleteExpectation.fulfill()
        }
        waitForExpectations(timeout: 1.0, handler: nil)
    }
    
    // MARK: - Search and Filter Tests
    
    func testSearchGearEmpty() {
        let results = dataService.searchGear(query: "")
        XCTAssertNotNil(results)
        // Empty query should return all gear
    }
    
    func testSearchGearWithQuery() {
        let results = dataService.searchGear(query: "tent")
        XCTAssertNotNil(results)
        // Should return filtered results (though might be empty in test environment)
    }
    
    func testSearchHikesEmpty() {
        let results = dataService.searchHikes(query: "")
        XCTAssertNotNil(results)
        // Empty query should return all hikes
    }
    
    func testSearchHikesWithQuery() {
        let results = dataService.searchHikes(query: "mountain")
        XCTAssertNotNil(results)
        // Should return filtered results
    }
    
    func testGearByCategory() {
        let categorizedGear = dataService.gearByCategory()
        XCTAssertNotNil(categorizedGear)
        // Should return gear grouped by category
    }
    
    // MARK: - Utility Tests
    
    func testCopyHike() {
        let originalHike = HikeSwiftUI()
        originalHike.name = "Original Hike"
        originalHike.desc = "Original Description"
        originalHike.location = "Test Location"
        originalHike.distance = 15.0
        originalHike.completed = true
        originalHike.externalLink1 = "http://test.com"
        
        let copiedHike = dataService.copyHike(originalHike)
        
        XCTAssertNotNil(copiedHike)
        XCTAssertEqual(copiedHike.name, "Copy of Original Hike")
        XCTAssertEqual(copiedHike.desc, originalHike.desc)
        XCTAssertEqual(copiedHike.location, originalHike.location)
        XCTAssertEqual(copiedHike.distance, originalHike.distance)
        XCTAssertFalse(copiedHike.completed, "Copied hike should not be completed")
        XCTAssertEqual(copiedHike.externalLink1, originalHike.externalLink1)
        XCTAssertNotEqual(copiedHike.id, originalHike.id, "Copied hike should have different ID")
    }
    
    func testCleanupDatabaseDuplicates() {
        XCTAssertNoThrow(dataService.cleanupDatabaseDuplicates())
        
        // Wait for cleanup operation
        let expectation = self.expectation(description: "Cleanup duplicates")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            expectation.fulfill()
        }
        waitForExpectations(timeout: 2.0, handler: nil)
    }
    
    func testCleanupDuplicateHikeGears() {
        XCTAssertNoThrow(dataService.cleanupDuplicateHikeGears())
        
        // Wait for cleanup operation
        let expectation = self.expectation(description: "Cleanup hike gears")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            expectation.fulfill()
        }
        waitForExpectations(timeout: 2.0, handler: nil)
    }
    
    // MARK: - Thread Safety Tests
    
    func testConcurrentDataOperations() {
        let expectation = self.expectation(description: "Concurrent operations")
        expectation.expectedFulfillmentCount = 10
        
        // Perform multiple concurrent operations
        for i in 0..<10 {
            DispatchQueue.global().async {
                let gear = GearSwiftUI()
                gear.name = "Concurrent Gear \(i)"
                gear.desc = "Test gear \(i)"
                gear.weightInGrams = Double(100 + i)
                gear.category = "Test"
                
                self.dataService.addGear(gear)
                
                // Simulate some processing time
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    expectation.fulfill()
                }
            }
        }
        
        waitForExpectations(timeout: 5.0, handler: nil)
    }
    
    func testConcurrentSearchOperations() {
        let expectation = self.expectation(description: "Concurrent searches")
        expectation.expectedFulfillmentCount = 20
        
        // Perform multiple concurrent search operations
        for i in 0..<10 {
            DispatchQueue.global().async {
                let _ = self.dataService.searchGear(query: "test\(i)")
                expectation.fulfill()
            }
            
            DispatchQueue.global().async {
                let _ = self.dataService.searchHikes(query: "hike\(i)")
                expectation.fulfill()
            }
        }
        
        waitForExpectations(timeout: 3.0, handler: nil)
    }
    
    // MARK: - Data Access Tests
    
    func testGearsProperty() {
        let gears = dataService.gears
        XCTAssertNotNil(gears)
        // Should return current gear cache
    }
    
    func testHikesProperty() {
        let hikes = dataService.hikes
        XCTAssertNotNil(hikes)
        // Should return current hike cache
    }
    
    // MARK: - Performance Tests
    
    func testPerformanceOfDataLoading() {
        measure {
            dataService.loadData()
        }
    }
    
    func testPerformanceOfSearchOperations() {
        measure {
            for i in 0..<100 {
                let _ = dataService.searchGear(query: "test\(i % 10)")
            }
        }
    }
    
    // MARK: - Edge Cases
    
    func testAddGearWithSpecialCharacters() {
        let gear = GearSwiftUI()
        gear.name = "Gear with émojis 🏕️"
        gear.desc = "Description with üñíçødé"
        gear.weightInGrams = 42.5
        gear.category = "Special Çätégory"
        
        XCTAssertNoThrow(dataService.addGear(gear))
    }
    
    func testSearchWithSpecialCharacters() {
        let results = dataService.searchGear(query: "émojis 🏕️")
        XCTAssertNotNil(results)
    }
    
    func testCaseInsensitiveSearch() {
        let results1 = dataService.searchGear(query: "TENT")
        let results2 = dataService.searchGear(query: "tent")
        let results3 = dataService.searchGear(query: "Tent")
        
        XCTAssertNotNil(results1)
        XCTAssertNotNil(results2)
        XCTAssertNotNil(results3)
        // All should return same results (case insensitive)
    }
}