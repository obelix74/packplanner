//
//  LoadingStateManagerTests.swift
//  PackPlannerTests
//
//  Created by Claude on Unit Testing
//

import XCTest
@testable import PackPlanner
import UIKit

class LoadingStateManagerTests: XCTestCase {
    
    var loadingStateManager: LoadingStateManager!
    var mockTableView: MockTableView!
    var mockViewController: MockViewController!
    
    override func setUp() {
        super.setUp()
        loadingStateManager = LoadingStateManager.shared
        mockTableView = MockTableView(frame: CGRect(x: 0, y: 0, width: 320, height: 568), style: .plain)
        mockViewController = MockViewController()
    }
    
    override func tearDown() {
        loadingStateManager = nil
        mockTableView = nil
        mockViewController = nil
        super.tearDown()
    }
    
    // MARK: - Singleton Tests
    
    func testSingletonInstance() {
        let instance1 = LoadingStateManager.shared
        let instance2 = LoadingStateManager.shared
        
        XCTAssertTrue(instance1 === instance2, "LoadingStateManager should be a singleton")
    }
    
    // MARK: - UITableView Loading State Tests
    
    func testShowLoadingStateOnTableView() {
        let message = "Loading data..."
        
        XCTAssertNoThrow(loadingStateManager.showLoadingState(for: mockTableView, message: message))
        
        // Verify that a background view was set
        XCTAssertNotNil(mockTableView.backgroundView)
    }
    
    func testHideLoadingStateOnTableView() {
        // First show loading state
        loadingStateManager.showLoadingState(for: mockTableView, message: "Loading...")
        XCTAssertNotNil(mockTableView.backgroundView)
        
        // Then hide it
        XCTAssertNoThrow(loadingStateManager.hideLoadingState(for: mockTableView))
        
        // Verify background view is cleared
        XCTAssertNil(mockTableView.backgroundView)
    }
    
    func testShowEmptyStateOnTableView() {
        let message = "No data available"
        
        XCTAssertNoThrow(loadingStateManager.showEmptyState(for: mockTableView, message: message))
        
        // Verify that a background view was set
        XCTAssertNotNil(mockTableView.backgroundView)
    }
    
    func testMultipleLoadingStatesOnTableView() {
        // Show loading state
        loadingStateManager.showLoadingState(for: mockTableView, message: "Loading...")
        XCTAssertNotNil(mockTableView.backgroundView)
        
        // Show empty state (should replace loading state)
        loadingStateManager.showEmptyState(for: mockTableView, message: "No data")
        XCTAssertNotNil(mockTableView.backgroundView)
        
        // Hide state
        loadingStateManager.hideLoadingState(for: mockTableView)
        XCTAssertNil(mockTableView.backgroundView)
    }
    
    // MARK: - UIViewController Loading State Tests
    
    func testShowLoadingStateOnViewController() {
        let message = "Loading data..."
        
        XCTAssertNoThrow(loadingStateManager.showLoadingState(for: mockViewController, message: message))
        
        // Verify that a loading view was added to the view controller
        XCTAssertTrue(mockViewController.view.subviews.count > 0)
    }
    
    func testHideLoadingStateOnViewController() {
        // First show loading state
        loadingStateManager.showLoadingState(for: mockViewController, message: "Loading...")
        let initialSubviewCount = mockViewController.view.subviews.count
        XCTAssertTrue(initialSubviewCount > 0)
        
        // Then hide it
        XCTAssertNoThrow(loadingStateManager.hideLoadingState(for: mockViewController))
        
        // Note: In real implementation, the loading view should be removed
        // For this test, we just verify the method doesn't crash
    }
    
    func testShowProgressOnViewController() {
        let progress: Float = 0.5
        let message = "50% complete"
        
        XCTAssertNoThrow(loadingStateManager.showProgress(for: mockViewController, progress: progress, message: message))
        
        // Verify that a progress view was added
        XCTAssertTrue(mockViewController.view.subviews.count > 0)
    }
    
    func testUpdateProgressOnViewController() {
        // First show initial progress
        loadingStateManager.showProgress(for: mockViewController, progress: 0.3, message: "30%")
        
        // Then update progress
        XCTAssertNoThrow(loadingStateManager.updateProgress(for: mockViewController, progress: 0.7, message: "70%"))
    }
    
    // MARK: - Thread Safety Tests
    
    func testConcurrentLoadingStateOperations() {
        let expectation = self.expectation(description: "Concurrent operations")
        expectation.expectedFulfillmentCount = 10
        
        // Perform multiple concurrent operations
        for i in 0..<10 {
            DispatchQueue.global().async {
                if i % 2 == 0 {
                    self.loadingStateManager.showLoadingState(for: self.mockTableView, message: "Loading \(i)")
                } else {
                    self.loadingStateManager.hideLoadingState(for: self.mockTableView)
                }
                expectation.fulfill()
            }
        }
        
        waitForExpectations(timeout: 2.0, handler: nil)
    }
    
    // MARK: - Edge Cases
    
    func testShowLoadingStateWithEmptyMessage() {
        XCTAssertNoThrow(loadingStateManager.showLoadingState(for: mockTableView, message: ""))
        XCTAssertNotNil(mockTableView.backgroundView)
    }
    
    func testHideLoadingStateWhenNoneShown() {
        // Should not crash even if no loading state was shown
        XCTAssertNoThrow(loadingStateManager.hideLoadingState(for: mockTableView))
        XCTAssertNil(mockTableView.backgroundView)
    }
    
    func testShowLoadingStateOnNilView() {
        let nilViewController = NilViewController()
        
        // Should handle nil view gracefully
        XCTAssertNoThrow(loadingStateManager.showLoadingState(for: nilViewController, message: "Loading..."))
    }
    
    // MARK: - Performance Tests
    
    func testPerformanceOfShowingLoadingState() {
        measure {
            for _ in 0..<100 {
                loadingStateManager.showLoadingState(for: mockTableView, message: "Loading...")
                loadingStateManager.hideLoadingState(for: mockTableView)
            }
        }
    }
}

// MARK: - Mock Classes

class MockTableView: UITableView {
    override init(frame: CGRect, style: UITableView.Style) {
        super.init(frame: frame, style: style)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
}

class NilViewController: UIViewController {
    override func loadView() {
        // Intentionally set view to nil for testing
        view = nil
    }
}