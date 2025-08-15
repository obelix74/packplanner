//
//  DependencyContainerTests.swift
//  PackPlannerTests
//
//  Created by Claude on Unit Testing
//

import XCTest
@testable import PackPlanner

class DependencyContainerTests: XCTestCase {
    
    var container: DependencyContainer!
    
    override func setUp() {
        super.setUp()
        container = DependencyContainer()
    }
    
    override func tearDown() {
        container = nil
        super.tearDown()
    }
    
    // MARK: - Registration Tests
    
    func testRegisterSingletonService() {
        let service = MockDataService()
        
        XCTAssertNoThrow(container.register(MockDataServiceProtocol.self, instance: service, lifetime: .singleton))
    }
    
    func testRegisterTransientService() {
        XCTAssertNoThrow(container.register(MockDataServiceProtocol.self, factory: { MockDataService() }, lifetime: .transient))
    }
    
    func testRegisterScopedService() {
        XCTAssertNoThrow(container.register(MockDataServiceProtocol.self, factory: { MockDataService() }, lifetime: .scoped))
    }
    
    func testRegisterWithFactory() {
        var factoryCallCount = 0
        
        container.register(MockDataServiceProtocol.self, factory: {
            factoryCallCount += 1
            return MockDataService()
        }, lifetime: .transient)
        
        // Resolve multiple times for transient service
        let _ = container.resolve(MockDataServiceProtocol.self)
        let _ = container.resolve(MockDataServiceProtocol.self)
        
        XCTAssertEqual(factoryCallCount, 2, "Factory should be called for each transient resolve")
    }
    
    // MARK: - Resolution Tests
    
    func testResolveSingletonService() {
        let service = MockDataService()
        container.register(MockDataServiceProtocol.self, instance: service, lifetime: .singleton)
        
        let resolved1 = container.resolve(MockDataServiceProtocol.self)
        let resolved2 = container.resolve(MockDataServiceProtocol.self)
        
        XCTAssertNotNil(resolved1)
        XCTAssertNotNil(resolved2)
        XCTAssertTrue(resolved1 === resolved2, "Singleton should return same instance")
    }
    
    func testResolveTransientService() {
        container.register(MockDataServiceProtocol.self, factory: { MockDataService() }, lifetime: .transient)
        
        let resolved1 = container.resolve(MockDataServiceProtocol.self)
        let resolved2 = container.resolve(MockDataServiceProtocol.self)
        
        XCTAssertNotNil(resolved1)
        XCTAssertNotNil(resolved2)
        XCTAssertFalse(resolved1 === resolved2, "Transient should return different instances")
    }
    
    func testResolveScopedService() {
        container.register(MockDataServiceProtocol.self, factory: { MockDataService() }, lifetime: .scoped)
        
        // First scope
        container.beginScope()
        let resolved1 = container.resolve(MockDataServiceProtocol.self)
        let resolved2 = container.resolve(MockDataServiceProtocol.self)
        container.endScope()
        
        // Second scope
        container.beginScope()
        let resolved3 = container.resolve(MockDataServiceProtocol.self)
        container.endScope()
        
        XCTAssertNotNil(resolved1)
        XCTAssertNotNil(resolved2)
        XCTAssertNotNil(resolved3)
        XCTAssertTrue(resolved1 === resolved2, "Scoped should return same instance within scope")
        XCTAssertFalse(resolved1 === resolved3, "Scoped should return different instances across scopes")
    }
    
    func testResolveUnregisteredService() {
        let resolved = container.resolve(MockDataServiceProtocol.self)
        XCTAssertNil(resolved, "Unregistered service should return nil")
    }
    
    // MARK: - Optional Resolution Tests
    
    func testOptionalResolveRegisteredService() {
        let service = MockDataService()
        container.register(MockDataServiceProtocol.self, instance: service, lifetime: .singleton)
        
        let resolved: MockDataServiceProtocol? = container.optionalResolve()
        XCTAssertNotNil(resolved)
    }
    
    func testOptionalResolveUnregisteredService() {
        let resolved: MockDataServiceProtocol? = container.optionalResolve()
        XCTAssertNil(resolved)
    }
    
    // MARK: - Scope Management Tests
    
    func testScopeManagement() {
        container.register(MockDataServiceProtocol.self, factory: { MockDataService() }, lifetime: .scoped)
        
        // Test multiple nested scopes
        container.beginScope()
        let service1 = container.resolve(MockDataServiceProtocol.self)
        
        container.beginScope()
        let service2 = container.resolve(MockDataServiceProtocol.self)
        container.endScope()
        
        let service3 = container.resolve(MockDataServiceProtocol.self)
        container.endScope()
        
        XCTAssertNotNil(service1)
        XCTAssertNotNil(service2)
        XCTAssertNotNil(service3)
        XCTAssertTrue(service1 === service3, "Should return same instance in same scope")
        XCTAssertFalse(service1 === service2, "Should return different instances in different scopes")
    }
    
    func testEndScopeWithoutBeginScope() {
        // Should not crash when ending scope without beginning one
        XCTAssertNoThrow(container.endScope())
    }
    
    // MARK: - Error Handling Tests
    
    func testRegisterSameServiceTwice() {
        let service1 = MockDataService()
        let service2 = MockDataService()
        
        container.register(MockDataServiceProtocol.self, instance: service1, lifetime: .singleton)
        
        // Registering same service again should replace the first registration
        XCTAssertNoThrow(container.register(MockDataServiceProtocol.self, instance: service2, lifetime: .singleton))
        
        let resolved = container.resolve(MockDataServiceProtocol.self)
        XCTAssertTrue(resolved === service2, "Second registration should replace first")
    }
    
    // MARK: - Thread Safety Tests
    
    func testConcurrentRegistrationAndResolution() {
        let expectation = self.expectation(description: "Concurrent operations")
        expectation.expectedFulfillmentCount = 20
        
        // Register services concurrently
        for i in 0..<10 {
            DispatchQueue.global().async {
                let service = MockDataService()
                service.identifier = "Service\(i)"
                self.container.register(MockDataServiceProtocol.self, instance: service, lifetime: .singleton)
                expectation.fulfill()
            }
        }
        
        // Resolve services concurrently
        for _ in 0..<10 {
            DispatchQueue.global().async {
                let _ = self.container.resolve(MockDataServiceProtocol.self)
                expectation.fulfill()
            }
        }
        
        waitForExpectations(timeout: 2.0, handler: nil)
    }
    
    // MARK: - Memory Management Tests
    
    func testWeakReferenceDoesNotRetainService() {
        weak var weakService: MockDataService?
        
        do {
            let service = MockDataService()
            weakService = service
            container.register(MockDataServiceProtocol.self, instance: service, lifetime: .singleton)
        }
        
        // Service should still be retained by container
        XCTAssertNotNil(weakService)
        
        // Clear container (if supported)
        container = DependencyContainer()
        
        // Service should now be deallocated
        XCTAssertNil(weakService, "Service should be deallocated when container is cleared")
    }
    
    // MARK: - Property Wrapper Tests
    
    func testInjectedPropertyWrapper() {
        let service = MockDataService()
        service.identifier = "TestService"
        
        DependencyContainer.shared.register(MockDataServiceProtocol.self, instance: service, lifetime: .singleton)
        
        let testClass = TestClassWithInjection()
        XCTAssertNotNil(testClass.dataService)
        XCTAssertEqual(testClass.dataService.identifier, "TestService")
    }
    
    func testOptionalInjectedPropertyWrapper() {
        // Don't register any service
        let testClass = TestClassWithOptionalInjection()
        XCTAssertNil(testClass.optionalDataService)
        
        // Now register service
        let service = MockDataService()
        service.identifier = "OptionalTestService"
        DependencyContainer.shared.register(MockDataServiceProtocol.self, instance: service, lifetime: .singleton)
        
        let testClass2 = TestClassWithOptionalInjection()
        XCTAssertNotNil(testClass2.optionalDataService)
        XCTAssertEqual(testClass2.optionalDataService?.identifier, "OptionalTestService")
    }
    
    // MARK: - Performance Tests
    
    func testPerformanceOfServiceResolution() {
        container.register(MockDataServiceProtocol.self, factory: { MockDataService() }, lifetime: .transient)
        
        measure {
            for _ in 0..<1000 {
                let _ = container.resolve(MockDataServiceProtocol.self)
            }
        }
    }
}

// MARK: - Mock Classes and Protocols

protocol MockDataServiceProtocol: AnyObject {
    var identifier: String { get set }
    func fetchData() -> String
}

class MockDataService: MockDataServiceProtocol {
    var identifier: String = "DefaultService"
    
    func fetchData() -> String {
        return "Mock data from \(identifier)"
    }
}

class TestClassWithInjection {
    @Injected var dataService: MockDataServiceProtocol
}

class TestClassWithOptionalInjection {
    @OptionalInjected var optionalDataService: MockDataServiceProtocol?
}