//
//  DataServiceTestsRefactored.swift
//  PackPlannerTests
//
//  Created by Claude on Unit Testing with Dependency Injection
//

import XCTest
@testable import PackPlanner

class DataServiceTestsRefactored: XCTestCase {
    
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
    
    // MARK: - Dependency Injection Tests
    
    func testDataServiceInjection() {
        // Given
        class TestClass {
            @Injected var dataService: DataServiceProtocol
        }
        
        // When
        let testInstance = TestClass()
        
        // Then
        XCTAssertTrue(testInstance.dataService is MockDataService)
    }
    
    // MARK: - Mock DataService Tests
    
    func testMockDataServiceAddGear() {
        // Given
        let gear = GearSwiftUI()
        gear.name = "Test Gear"
        gear.desc = "Test Description"
        gear.weightInGrams = 100
        gear.category = "Clothing"
        
        // When
        mockDataService.addGear(gear)
        
        // Then
        XCTAssertTrue(mockDataService.addGearCalled)
        XCTAssertEqual(mockDataService.gears.count, 1)
        XCTAssertEqual(mockDataService.gears.first?.name, "Test Gear")
    }
    
    func testMockDataServiceUpdateGear() {
        // Given
        let gear = GearSwiftUI()
        gear.name = "Original Name"
        gear.desc = "Original Description"
        gear.weightInGrams = 100
        gear.category = "Clothing"
        
        mockDataService.addGear(gear)
        
        // When
        gear.name = "Updated Name"
        mockDataService.updateGear(gear)
        
        // Then
        XCTAssertTrue(mockDataService.updateGearCalled)
        XCTAssertEqual(mockDataService.gears.first?.name, "Updated Name")
    }
    
    func testMockDataServiceDeleteGear() {
        // Given
        let gear = GearSwiftUI()
        gear.name = "Gear to Delete"
        gear.category = "Equipment"
        
        mockDataService.addGear(gear)
        XCTAssertEqual(mockDataService.gears.count, 1)
        
        // When
        mockDataService.deleteGear(gear)
        
        // Then
        XCTAssertTrue(mockDataService.deleteGearCalled)
        XCTAssertEqual(mockDataService.gears.count, 0)
    }
    
    func testMockDataServiceAddHike() {
        // Given
        let hike = HikeSwiftUI()
        hike.name = "Test Hike"
        hike.desc = "Test Description"
        hike.location = "Test Location"
        hike.distance = "10.5"
        hike.completed = false
        
        // When
        mockDataService.addHike(hike)
        
        // Then
        XCTAssertTrue(mockDataService.addHikeCalled)
        XCTAssertEqual(mockDataService.hikes.count, 1)
        XCTAssertEqual(mockDataService.hikes.first?.name, "Test Hike")
    }
    
    func testMockDataServiceUpdateHike() {
        // Given
        let hike = HikeSwiftUI()
        hike.name = "Original Hike"
        hike.desc = "Original Description"
        hike.location = "Original Location"
        
        mockDataService.addHike(hike)
        
        // When
        hike.desc = "Updated Description"
        hike.completed = true
        mockDataService.updateHike(hike)
        
        // Then
        XCTAssertTrue(mockDataService.updateHikeCalled)
        XCTAssertEqual(mockDataService.hikes.first?.desc, "Updated Description")
        XCTAssertTrue(mockDataService.hikes.first?.completed == true)
    }
    
    func testMockDataServiceDeleteHike() {
        // Given
        let hike = HikeSwiftUI()
        hike.name = "Hike to Delete"
        hike.location = "Test Location"
        
        mockDataService.addHike(hike)
        XCTAssertEqual(mockDataService.hikes.count, 1)
        
        // When
        mockDataService.deleteHike(hike)
        
        // Then
        XCTAssertTrue(mockDataService.deleteHikeCalled)
        XCTAssertEqual(mockDataService.hikes.count, 0)
    }
    
    // MARK: - Search Functionality Tests
    
    func testSearchGearEmpty() {
        // Given
        let gear1 = GearSwiftUI()
        gear1.name = "Tent"
        gear1.category = "Shelter"
        
        let gear2 = GearSwiftUI()
        gear2.name = "Sleeping Bag"
        gear2.category = "Sleep"
        
        mockDataService.addGear(gear1)
        mockDataService.addGear(gear2)
        
        // When
        let results = mockDataService.searchGear(query: "")
        
        // Then
        XCTAssertEqual(results.count, 2)
    }
    
    func testSearchGearWithQuery() {
        // Given
        let gear1 = GearSwiftUI()
        gear1.name = "Tent"
        gear1.category = "Shelter"
        
        let gear2 = GearSwiftUI()
        gear2.name = "Sleeping Bag"
        gear2.desc = "Down-filled tent accessory"
        
        mockDataService.addGear(gear1)
        mockDataService.addGear(gear2)
        
        // When
        let results = mockDataService.searchGear(query: "tent")
        
        // Then
        XCTAssertEqual(results.count, 2) // Both match "tent" - one in name, one in desc
    }
    
    func testSearchHikesWithQuery() {
        // Given
        let hike1 = HikeSwiftUI()
        hike1.name = "Mount Whitney"
        hike1.location = "California"
        
        let hike2 = HikeSwiftUI()
        hike2.name = "Half Dome"
        hike2.desc = "Epic granite climb in mountains"
        
        mockDataService.addHike(hike1)
        mockDataService.addHike(hike2)
        
        // When
        let califResults = mockDataService.searchHikes(query: "California")
        let mountainResults = mockDataService.searchHikes(query: "mountain")
        
        // Then
        XCTAssertEqual(califResults.count, 1)
        XCTAssertEqual(califResults.first?.name, "Mount Whitney")
        
        XCTAssertEqual(mountainResults.count, 1)
        XCTAssertEqual(mountainResults.first?.name, "Half Dome")
    }
    
    func testGearByCategory() {
        // Given
        let gear1 = GearSwiftUI()
        gear1.name = "Tent"
        gear1.category = "Shelter"
        
        let gear2 = GearSwiftUI()
        gear2.name = "Backpack"
        gear2.category = "Shelter"
        
        let gear3 = GearSwiftUI()
        gear3.name = "Sleeping Bag"
        gear3.category = "Sleep"
        
        mockDataService.addGear(gear1)
        mockDataService.addGear(gear2)
        mockDataService.addGear(gear3)
        
        // When
        let categorizedGear = mockDataService.gearByCategory()
        
        // Then
        XCTAssertEqual(categorizedGear.keys.count, 2)
        XCTAssertEqual(categorizedGear["Shelter"]?.count, 2)
        XCTAssertEqual(categorizedGear["Sleep"]?.count, 1)
    }
    
    // MARK: - Copy Functionality Tests
    
    func testCopyHike() {
        // Given
        let originalHike = HikeSwiftUI()
        originalHike.name = "Original Hike"
        originalHike.desc = "Original Description"
        originalHike.location = "Test Location"
        originalHike.distance = "15.0"
        originalHike.completed = true
        originalHike.externalLink1 = "http://test.com"
        
        // When
        let copiedHike = mockDataService.copyHike(originalHike)
        
        // Then
        XCTAssertNotNil(copiedHike)
        XCTAssertEqual(copiedHike.name, "Copy of Original Hike")
        XCTAssertEqual(copiedHike.desc, originalHike.desc)
        XCTAssertEqual(copiedHike.location, originalHike.location)
        XCTAssertEqual(copiedHike.distance, originalHike.distance)
        XCTAssertFalse(copiedHike.completed, "Copied hike should not be completed")
        XCTAssertEqual(copiedHike.externalLink1, originalHike.externalLink1)
        XCTAssertNotEqual(copiedHike.id, originalHike.id, "Copied hike should have different ID")
    }
    
    // MARK: - Load Data Tests
    
    func testLoadData() {
        // When
        mockDataService.loadData()
        
        // Then
        XCTAssertTrue(mockDataService.loadDataCalled)
    }
    
    // MARK: - Cleanup Tests
    
    func testCleanupOperations() {
        // When
        mockDataService.cleanupDatabaseDuplicates()
        mockDataService.cleanupDuplicateHikeGears()
        
        // Then
        XCTAssertNoThrow(mockDataService.cleanupDatabaseDuplicates())
        XCTAssertNoThrow(mockDataService.cleanupDuplicateHikeGears())
    }
    
    // MARK: - Integration Tests with Other Services
    
    func testIntegrationWithInjectedServices() {
        // Given
        class TestViewController {
            @Injected var dataService: DataServiceProtocol
            @Injected var hikeService: HikeListService
            @Injected var gearService: GearListService
            
            func performTestOperations() -> Bool {
                let gear = GearSwiftUI()
                gear.name = "Integration Test Gear"
                gear.category = "Test"
                
                dataService.addGear(gear)
                
                let hike = HikeSwiftUI()
                hike.name = "Integration Test Hike"
                
                hikeService.copyHike(hike)
                
                return dataService.gears.count > 0
            }
        }
        
        // When
        let viewController = TestViewController()
        let result = viewController.performTestOperations()
        
        // Then
        XCTAssertTrue(result)
        XCTAssertTrue(viewController.dataService is MockDataService)
        XCTAssertTrue(viewController.hikeService is MockHikeListService)
        XCTAssertTrue(viewController.gearService is MockGearListService)
    }
    
    // MARK: - Performance Tests
    
    func testPerformanceOfMockOperations() {
        measure {
            for i in 0..<1000 {
                let gear = GearSwiftUI()
                gear.name = "Performance Test Gear \(i)"
                gear.category = "Test"
                mockDataService.addGear(gear)
            }
        }
    }
    
    // MARK: - Edge Cases
    
    func testEmptyDataOperations() {
        // Test operations on empty data sets
        XCTAssertEqual(mockDataService.gears.count, 0)
        XCTAssertEqual(mockDataService.hikes.count, 0)
        
        let emptyGearSearch = mockDataService.searchGear(query: "nonexistent")
        let emptyHikeSearch = mockDataService.searchHikes(query: "nonexistent")
        
        XCTAssertEqual(emptyGearSearch.count, 0)
        XCTAssertEqual(emptyHikeSearch.count, 0)
    }
    
    func testSpecialCharactersInSearch() {
        // Given
        let gear = GearSwiftUI()
        gear.name = "Gear with émojis 🏕️"
        gear.desc = "Description with üñíçødé"
        gear.category = "Special Çätégory"
        
        mockDataService.addGear(gear)
        
        // When
        let results = mockDataService.searchGear(query: "émojis")
        
        // Then
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.name, "Gear with émojis 🏕️")
    }
}