//
//  DataServiceTests.swift
//  PackPlannerTests
//
//  Created by Claude on Unit Testing with Dependency Injection
//

import XCTest
@testable import PackPlanner

class DataServiceTests: XCTestCase {

    var mockDataService: MockDataService!
    var container: DependencyContainer!

    override func setUp() {
        super.setUp()

        // Setup dependency injection with mock services
        container = DITestHelper.setupMockContainer()

        // Get mock data service for testing
        mockDataService = MockDataService()
    }

    override func tearDown() {
        DITestHelper.resetToProductionContainer()
        mockDataService = nil
        container = nil
        super.tearDown()
    }

    // MARK: - Initialization Tests

    func testDataServiceSingleton() {
        let instance1 = DataService.shared
        let instance2 = DataService.shared

        XCTAssertTrue(instance1 === instance2, "DataService should be a singleton")
    }

    func testLoadData() {
        mockDataService.loadData()
        XCTAssertTrue(mockDataService.loadDataCalled)
    }

    // MARK: - Gear CRUD Tests

    func testAddGear() {
        let gear = GearSwiftUI()
        gear.name = "Test Gear"
        gear.desc = "Test Description"
        gear.weightInGrams = 100
        gear.category = "Clothing"

        mockDataService.addGear(gear)

        XCTAssertTrue(mockDataService.addGearCalled)
        XCTAssertEqual(mockDataService.gears.count, 1)
        XCTAssertEqual(mockDataService.gears.first?.name, "Test Gear")
    }

    func testUpdateGear() {
        let gear = GearSwiftUI()
        gear.name = "Original Name"
        gear.desc = "Original Description"
        gear.weightInGrams = 100
        gear.category = "Clothing"

        mockDataService.addGear(gear)

        gear.name = "Updated Name"
        gear.desc = "Updated Description"
        mockDataService.updateGear(gear)

        XCTAssertTrue(mockDataService.updateGearCalled)
        XCTAssertEqual(mockDataService.gears.first?.name, "Updated Name")
    }

    func testDeleteGear() {
        let gear = GearSwiftUI()
        gear.name = "Gear to Delete"
        gear.desc = "Will be deleted"
        gear.weightInGrams = 50
        gear.category = "Equipment"

        mockDataService.addGear(gear)
        XCTAssertEqual(mockDataService.gears.count, 1)

        mockDataService.deleteGear(gear)

        XCTAssertTrue(mockDataService.deleteGearCalled)
        XCTAssertEqual(mockDataService.gears.count, 0)
    }

    // MARK: - Hike CRUD Tests

    func testAddHike() {
        let hike = HikeSwiftUI()
        hike.name = "Test Hike"
        hike.desc = "Test Description"
        hike.location = "Test Location"
        hike.distance = "10.5"
        hike.completed = false

        mockDataService.addHike(hike)

        XCTAssertTrue(mockDataService.addHikeCalled)
        XCTAssertEqual(mockDataService.hikes.count, 1)
        XCTAssertEqual(mockDataService.hikes.first?.name, "Test Hike")
    }

    func testUpdateHike() {
        let hike = HikeSwiftUI()
        hike.name = "Original Hike"
        hike.desc = "Original Description"
        hike.location = "Original Location"
        hike.distance = "5.0"
        hike.completed = false

        mockDataService.addHike(hike)

        hike.desc = "Updated Description"
        hike.completed = true
        mockDataService.updateHike(hike)

        XCTAssertTrue(mockDataService.updateHikeCalled)
        XCTAssertEqual(mockDataService.hikes.first?.desc, "Updated Description")
        XCTAssertTrue(mockDataService.hikes.first?.completed == true)
    }

    func testDeleteHike() {
        let hike = HikeSwiftUI()
        hike.name = "Hike to Delete"
        hike.desc = "Will be deleted"
        hike.location = "Test Location"
        hike.distance = "3.0"
        hike.completed = false

        mockDataService.addHike(hike)
        XCTAssertEqual(mockDataService.hikes.count, 1)

        mockDataService.deleteHike(hike)

        XCTAssertTrue(mockDataService.deleteHikeCalled)
        XCTAssertEqual(mockDataService.hikes.count, 0)
    }

    // MARK: - Search and Filter Tests

    func testSearchGearEmpty() {
        let gear1 = GearSwiftUI()
        gear1.name = "Tent"
        gear1.category = "Shelter"

        let gear2 = GearSwiftUI()
        gear2.name = "Sleeping Bag"
        gear2.category = "Sleep"

        mockDataService.addGear(gear1)
        mockDataService.addGear(gear2)

        let results = mockDataService.searchGear(query: "")
        XCTAssertEqual(results.count, 2)
    }

    func testSearchGearWithQuery() {
        let gear1 = GearSwiftUI()
        gear1.name = "Tent"
        gear1.category = "Shelter"

        let gear2 = GearSwiftUI()
        gear2.name = "Sleeping Bag"
        gear2.category = "Sleep"

        mockDataService.addGear(gear1)
        mockDataService.addGear(gear2)

        let results = mockDataService.searchGear(query: "tent")
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.name, "Tent")
    }

    func testSearchHikesEmpty() {
        let hike = HikeSwiftUI()
        hike.name = "Test Hike"
        hike.location = "Mountain"

        mockDataService.addHike(hike)

        let results = mockDataService.searchHikes(query: "")
        XCTAssertEqual(results.count, 1)
    }

    func testSearchHikesWithQuery() {
        let hike1 = HikeSwiftUI()
        hike1.name = "Mountain Trail"
        hike1.location = "Colorado"

        let hike2 = HikeSwiftUI()
        hike2.name = "Beach Walk"
        hike2.location = "California"

        mockDataService.addHike(hike1)
        mockDataService.addHike(hike2)

        let results = mockDataService.searchHikes(query: "mountain")
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.name, "Mountain Trail")
    }

    func testGearByCategory() {
        let gear1 = GearSwiftUI()
        gear1.name = "Tent"
        gear1.category = "Shelter"

        let gear2 = GearSwiftUI()
        gear2.name = "Sleeping Bag"
        gear2.category = "Sleep"

        let gear3 = GearSwiftUI()
        gear3.name = "Tarp"
        gear3.category = "Shelter"

        mockDataService.addGear(gear1)
        mockDataService.addGear(gear2)
        mockDataService.addGear(gear3)

        let categorizedGear = mockDataService.gearByCategory()
        XCTAssertEqual(categorizedGear.keys.count, 2)
        XCTAssertEqual(categorizedGear["Shelter"]?.count, 2)
        XCTAssertEqual(categorizedGear["Sleep"]?.count, 1)
    }

    // MARK: - Utility Tests

    func testCopyHike() {
        let originalHike = HikeSwiftUI()
        originalHike.name = "Original Hike"
        originalHike.desc = "Original Description"
        originalHike.location = "Test Location"
        originalHike.distance = "15.0"
        originalHike.completed = true
        originalHike.externalLink1 = "http://test.com"

        let copiedHike = mockDataService.copyHike(originalHike)

        XCTAssertEqual(copiedHike.name, "Copy of Original Hike")
        XCTAssertEqual(copiedHike.desc, originalHike.desc)
        XCTAssertEqual(copiedHike.location, originalHike.location)
        XCTAssertEqual(copiedHike.distance, originalHike.distance)
        XCTAssertFalse(copiedHike.completed, "Copied hike should not be completed")
        XCTAssertEqual(copiedHike.externalLink1, originalHike.externalLink1)
        XCTAssertNotEqual(copiedHike.id, originalHike.id, "Copied hike should have different ID")
    }

    func testCleanupOperations() {
        XCTAssertNoThrow(mockDataService.cleanupDatabaseDuplicates())
        XCTAssertNoThrow(mockDataService.cleanupDuplicateHikeGears())
    }

    // MARK: - Edge Cases

    func testAddGearWithSpecialCharacters() {
        let gear = GearSwiftUI()
        gear.name = "Gear with émojis"
        gear.desc = "Description with üñíçødé"
        gear.weightInGrams = 42.5
        gear.category = "Special"

        mockDataService.addGear(gear)

        XCTAssertEqual(mockDataService.gears.count, 1)
        XCTAssertEqual(mockDataService.gears.first?.name, "Gear with émojis")
    }

    func testSearchWithSpecialCharacters() {
        let gear = GearSwiftUI()
        gear.name = "Gear with émojis"
        gear.category = "Test"

        mockDataService.addGear(gear)

        let results = mockDataService.searchGear(query: "émojis")
        XCTAssertEqual(results.count, 1)
    }

    func testCaseInsensitiveSearch() {
        let gear = GearSwiftUI()
        gear.name = "Tent"
        gear.category = "Shelter"

        mockDataService.addGear(gear)

        let results1 = mockDataService.searchGear(query: "TENT")
        let results2 = mockDataService.searchGear(query: "tent")
        let results3 = mockDataService.searchGear(query: "Tent")

        XCTAssertEqual(results1.count, 1)
        XCTAssertEqual(results2.count, 1)
        XCTAssertEqual(results3.count, 1)
    }

    // MARK: - Performance Tests

    func testPerformanceOfMockOperations() {
        measure {
            for i in 0..<100 {
                let gear = GearSwiftUI()
                gear.name = "Performance Test Gear \(i)"
                gear.category = "Test"
                mockDataService.addGear(gear)
            }
        }
    }
}
