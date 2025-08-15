//
//  DependencyInjectionTests.swift
//  PackPlannerTests
//
//  Created by Claude on Dependency Injection Testing
//

import XCTest
@testable import PackPlanner

class DependencyInjectionTests: XCTestCase {
    
    var container: DependencyContainer!
    
    override func setUp() {
        super.setUp()
        container = DITestHelper.setupMockContainer()
    }
    
    override func tearDown() {
        DITestHelper.resetToProductionContainer()
        super.tearDown()
    }
    
    // MARK: - Container Resolution Tests
    
    func testContainerResolvesHikeListService() {
        // Given
        let service: HikeListService? = container.optionalResolve(HikeListService.self)
        
        // Then
        XCTAssertNotNil(service)
        XCTAssertTrue(service is MockHikeListService)
    }
    
    func testContainerResolvesGearListService() {
        // Given
        let service: GearListService? = container.optionalResolve(GearListService.self)
        
        // Then
        XCTAssertNotNil(service)
        XCTAssertTrue(service is MockGearListService)
    }
    
    func testContainerResolvesAlertService() {
        // Given
        let service: AlertService? = container.optionalResolve(AlertService.self)
        
        // Then
        XCTAssertNotNil(service)
        XCTAssertTrue(service is MockAlertService)
    }
    
    func testContainerResolvesExportService() {
        // Given
        let service: ExportService? = container.optionalResolve(ExportService.self)
        
        // Then
        XCTAssertNotNil(service)
        XCTAssertTrue(service is MockExportService)
    }
    
    func testContainerResolvesDataService() {
        // Given
        let service: DataServiceProtocol? = container.optionalResolve(DataServiceProtocol.self)
        
        // Then
        XCTAssertNotNil(service)
        XCTAssertTrue(service is MockDataService)
    }
    
    // MARK: - Property Wrapper Tests
    
    func testInjectedPropertyWrapper() {
        // Given
        struct TestStruct {
            @Injected var hikeService: HikeListService
        }
        
        // When
        let testStruct = TestStruct()
        
        // Then
        XCTAssertTrue(testStruct.hikeService is MockHikeListService)
    }
    
    func testOptionalInjectedPropertyWrapper() {
        // Given
        struct TestStruct {
            @OptionalInjected var gearService: GearListService?
        }
        
        // When
        let testStruct = TestStruct()
        
        // Then
        XCTAssertNotNil(testStruct.gearService)
        XCTAssertTrue(testStruct.gearService is MockGearListService)
    }
    
    // MARK: - Mock Service Behavior Tests
    
    func testMockHikeListService() {
        // Given
        let mockService = MockHikeListService()
        mockService.shouldShowWelcome = true
        
        let testHike = HikeSwiftUI()
        testHike.name = "Test Hike"
        testHike.desc = "A test hike"
        testHike.location = "Test Location"
        
        // When
        mockService.copyHike(testHike)
        
        // Then
        XCTAssertTrue(mockService.copyHikeCalled)
        XCTAssertEqual(mockService.mockHikes.count, 1)
        XCTAssertEqual(mockService.mockHikes.first?.name, "Copy of Test Hike")
        XCTAssertTrue(mockService.shouldShowWelcomeMessage(hikeCount: 0))
        
        let (title, message) = mockService.getWelcomeMessage()
        XCTAssertEqual(title, "Mock Welcome")
        XCTAssertEqual(message, "Mock message for testing")
    }
    
    func testMockGearListService() {
        // Given
        let mockService = MockGearListService()
        
        let testGear = GearSwiftUI()
        testGear.name = "Test Gear"
        testGear.category = "Testing"
        testGear.weightInGrams = 100.0
        
        let expectation = self.expectation(description: "Duplicate gear completion")
        
        // When
        mockService.duplicateGear(testGear) { success in
            XCTAssertTrue(success)
            expectation.fulfill()
        }
        
        // Then
        waitForExpectations(timeout: 1.0)
        XCTAssertTrue(mockService.duplicateGearCalled)
        XCTAssertEqual(mockService.mockGears.count, 1)
        XCTAssertEqual(mockService.mockGears.first?.name, "Test Gear Copy")
    }
    
    func testMockAlertService() {
        // Given
        let mockService = MockAlertService()
        var confirmCalled = false
        var cancelCalled = false
        
        // When
        let deleteAlert = mockService.createDeleteConfirmationAlert(
            itemName: "Test Item",
            onConfirm: { confirmCalled = true },
            onCancel: { cancelCalled = true }
        )
        
        let welcomeAlert = mockService.createWelcomeAlert(
            title: "Test Title",
            message: "Test Message"
        )
        
        // Then
        XCTAssertTrue(mockService.deleteAlertCreated)
        XCTAssertEqual(mockService.lastDeleteItemName, "Test Item")
        XCTAssertNotNil(deleteAlert)
        
        XCTAssertTrue(mockService.welcomeAlertCreated)
        XCTAssertEqual(mockService.lastWelcomeTitle, "Test Title")
        XCTAssertEqual(mockService.lastWelcomeMessage, "Test Message")
        XCTAssertNotNil(welcomeAlert)
    }
    
    func testMockDataService() {
        // Given
        let mockService = MockDataService()
        
        let testGear = GearSwiftUI()
        testGear.name = "Test Gear"
        
        let testHike = HikeSwiftUI()
        testHike.name = "Test Hike"
        
        // When
        mockService.addGear(testGear)
        mockService.addHike(testHike)
        mockService.loadData()
        
        // Then
        XCTAssertTrue(mockService.addGearCalled)
        XCTAssertTrue(mockService.addHikeCalled)
        XCTAssertTrue(mockService.loadDataCalled)
        XCTAssertEqual(mockService.gears.count, 1)
        XCTAssertEqual(mockService.hikes.count, 1)
    }
    
    // MARK: - Search Logic Tests
    
    func testHikeSearchLogic() {
        // Given
        let mockService = MockHikeListService()
        
        let hike1 = HikeSwiftUI()
        hike1.name = "Mount Whitney"
        hike1.location = "California"
        
        let hike2 = HikeSwiftUI()
        hike2.name = "Half Dome"
        hike2.desc = "Epic granite climb"
        
        let hike3 = HikeSwiftUI()
        hike3.name = "Angels Landing"
        hike3.location = "Utah"
        
        let allHikes = [hike1, hike2, hike3]
        
        // When
        let calResults = mockService.performSearch(items: allHikes, query: "California")
        let graniteResults = mockService.performSearch(items: allHikes, query: "granite")
        let emptyResults = mockService.performSearch(items: allHikes, query: "")
        
        // Then
        XCTAssertEqual(calResults.count, 1)
        XCTAssertEqual(calResults.first?.name, "Mount Whitney")
        
        XCTAssertEqual(graniteResults.count, 1)
        XCTAssertEqual(graniteResults.first?.name, "Half Dome")
        
        XCTAssertEqual(emptyResults.count, 3)
    }
    
    func testGearSearchLogic() {
        // Given
        let mockService = MockGearListService()
        
        let gear1 = GearSwiftUI()
        gear1.name = "Tent"
        gear1.category = "Shelter"
        
        let gear2 = GearSwiftUI()
        gear2.name = "Sleeping Bag"
        gear2.desc = "Down filled"
        
        let gear3 = GearSwiftUI()
        gear3.name = "Backpack"
        gear3.category = "Shelter" // Testing category grouping
        
        let allGears = [gear1, gear2, gear3]
        
        // When
        let shelterResults = mockService.performSearch(items: allGears, query: "Shelter")
        let downResults = mockService.performSearch(items: allGears, query: "Down")
        
        let grouped = mockService.groupGearsByCategory(allGears)
        let sortedCategories = mockService.sortedCategories(from: grouped)
        
        // Then
        XCTAssertEqual(shelterResults.count, 2)
        XCTAssertEqual(downResults.count, 1)
        XCTAssertEqual(downResults.first?.name, "Sleeping Bag")
        
        XCTAssertEqual(grouped.keys.count, 2) // "Shelter" and "" (empty category)
        XCTAssertEqual(grouped["Shelter"]?.count, 2)
        XCTAssertTrue(sortedCategories.contains("Shelter"))
    }
    
    // MARK: - Singleton Pattern Tests
    
    func testSingletonInstancesAreTheSame() {
        // Given
        let service1: HikeListService? = container.optionalResolve(HikeListService.self)
        let service2: HikeListService? = container.optionalResolve(HikeListService.self)
        
        // Then
        XCTAssertNotNil(service1)
        XCTAssertNotNil(service2)
        
        // Check that they're the same instance (reference equality)
        XCTAssertTrue(service1 as AnyObject === service2 as AnyObject)
    }
    
    func testClearSingletonInstances() {
        // Given
        let service1: HikeListService? = container.optionalResolve(HikeListService.self)
        
        // When
        container.clearSingletonInstances()
        let service2: HikeListService? = container.optionalResolve(HikeListService.self)
        
        // Then
        XCTAssertNotNil(service1)
        XCTAssertNotNil(service2)
        
        // They should be different instances after clearing
        XCTAssertFalse(service1 as AnyObject === service2 as AnyObject)
    }
    
    // MARK: - Error Handling Tests
    
    func testUnregisteredServiceThrows() {
        // Given
        let container = DependencyContainer.shared
        container.unregister(HikeListService.self)
        
        // When/Then
        XCTAssertThrowsError(try container.resolve(HikeListService.self)) { error in
            XCTAssertTrue(error is DIError)
            if case DIError.serviceNotRegistered(let service) = error {
                XCTAssertTrue(service.contains("HikeListService"))
            } else {
                XCTFail("Expected serviceNotRegistered error")
            }
        }
    }
}

// MARK: - Integration Tests

extension DependencyInjectionTests {
    
    func testFullIntegrationWithPropertyWrappers() {
        // Given
        class TestController {
            @Injected var hikeService: HikeListService
            @Injected var gearService: GearListService
            @Injected var alertService: AlertService
            
            func performOperations() -> Bool {
                let testHike = HikeSwiftUI()
                testHike.name = "Integration Test Hike"
                
                hikeService.copyHike(testHike)
                
                let testGear = GearSwiftUI()
                testGear.name = "Integration Test Gear"
                
                var gearDuplicateSuccess = false
                let expectation = XCTestExpectation(description: "Gear duplicate")
                
                gearService.duplicateGear(testGear) { success in
                    gearDuplicateSuccess = success
                    expectation.fulfill()
                }
                
                let result = XCTWaiter.wait(for: [expectation], timeout: 1.0)
                return result == .completed && gearDuplicateSuccess
            }
        }
        
        // When
        let controller = TestController()
        let success = controller.performOperations()
        
        // Then
        XCTAssertTrue(success)
        XCTAssertTrue(controller.hikeService is MockHikeListService)
        XCTAssertTrue(controller.gearService is MockGearListService)
        XCTAssertTrue(controller.alertService is MockAlertService)
        
        // Verify operations were called on mocks
        let mockHikeService = controller.hikeService as! MockHikeListService
        let mockGearService = controller.gearService as! MockGearListService
        
        XCTAssertTrue(mockHikeService.copyHikeCalled)
        XCTAssertTrue(mockGearService.duplicateGearCalled)
    }
}