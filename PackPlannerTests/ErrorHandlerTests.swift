//
//  ErrorHandlerTests.swift
//  PackPlannerTests
//
//  Created by Claude on Unit Testing
//

import XCTest
@testable import PackPlanner

class ErrorHandlerTests: XCTestCase {
    
    var errorHandler: ErrorHandler!
    var mockViewController: MockViewController!
    
    override func setUp() {
        super.setUp()
        errorHandler = ErrorHandler.shared
        mockViewController = MockViewController()
    }
    
    override func tearDown() {
        errorHandler = nil
        mockViewController = nil
        super.tearDown()
    }
    
    // MARK: - Error Logging Tests
    
    func testLogError() {
        let testError = PackPlannerError.databaseError("Test database error")
        let context = "Test context"
        
        // Since print statements can't be easily captured in unit tests,
        // we verify the method doesn't crash and handles the error gracefully
        XCTAssertNoThrow(errorHandler.logError(testError, context: context))
    }
    
    func testLogErrorWithoutContext() {
        let testError = PackPlannerError.validationError("Test validation error")
        
        XCTAssertNoThrow(errorHandler.logError(testError))
    }
    
    // MARK: - PackPlannerError Tests
    
    func testPackPlannerErrorDescriptions() {
        let databaseError = PackPlannerError.databaseError("DB failed")
        XCTAssertEqual(databaseError.errorDescription, "Database Error: DB failed")
        
        let validationError = PackPlannerError.validationError("Invalid input")
        XCTAssertEqual(validationError.errorDescription, "Validation Error: Invalid input")
        
        let networkError = PackPlannerError.networkError("No connection")
        XCTAssertEqual(networkError.errorDescription, "Network Error: No connection")
        
        let fileSystemError = PackPlannerError.fileSystemError("Disk full")
        XCTAssertEqual(fileSystemError.errorDescription, "File System Error: Disk full")
        
        let userInputError = PackPlannerError.userInputError("Bad input")
        XCTAssertEqual(userInputError.errorDescription, "Input Error: Bad input")
        
        let unknownError = PackPlannerError.unknownError("Mystery")
        XCTAssertEqual(unknownError.errorDescription, "Unknown Error: Mystery")
    }
    
    func testPackPlannerErrorRecoverySuggestions() {
        let databaseError = PackPlannerError.databaseError("DB failed")
        XCTAssertTrue(databaseError.recoverySuggestion?.contains("restarting") == true)
        
        let validationError = PackPlannerError.validationError("Invalid input")
        XCTAssertTrue(validationError.recoverySuggestion?.contains("check your input") == true)
        
        let networkError = PackPlannerError.networkError("No connection")
        XCTAssertTrue(networkError.recoverySuggestion?.contains("internet connection") == true)
        
        let fileSystemError = PackPlannerError.fileSystemError("Disk full")
        XCTAssertTrue(fileSystemError.recoverySuggestion?.contains("storage space") == true)
        
        let userInputError = PackPlannerError.userInputError("Bad input")
        XCTAssertTrue(userInputError.recoverySuggestion?.contains("correct the highlighted") == true)
        
        let unknownError = PackPlannerError.unknownError("Mystery")
        XCTAssertTrue(unknownError.recoverySuggestion?.contains("try again") == true)
    }
    
    // MARK: - Validation Tests
    
    func testValidateGearInputSuccess() {
        let result = errorHandler.validateGearInput(name: "Test Gear", weight: "100.5", category: "Clothing")
        
        switch result {
        case .success():
            XCTAssertTrue(true, "Validation should succeed")
        case .failure(_):
            XCTFail("Validation should not fail with valid input")
        }
    }
    
    func testValidateGearInputFailureEmptyName() {
        let result = errorHandler.validateGearInput(name: "", weight: "100.5", category: "Clothing")
        
        switch result {
        case .success():
            XCTFail("Validation should fail with empty name")
        case .failure(let error):
            XCTAssertTrue(error.errorDescription?.contains("name is required") == true)
        }
    }
    
    func testValidateGearInputFailureNilName() {
        let result = errorHandler.validateGearInput(name: nil, weight: "100.5", category: "Clothing")
        
        switch result {
        case .success():
            XCTFail("Validation should fail with nil name")
        case .failure(let error):
            XCTAssertTrue(error.errorDescription?.contains("name is required") == true)
        }
    }
    
    func testValidateGearInputFailureInvalidWeight() {
        let result = errorHandler.validateGearInput(name: "Test Gear", weight: "invalid", category: "Clothing")
        
        switch result {
        case .success():
            XCTFail("Validation should fail with invalid weight")
        case .failure(let error):
            XCTAssertTrue(error.errorDescription?.contains("Valid weight is required") == true)
        }
    }
    
    func testValidateGearInputFailureNegativeWeight() {
        let result = errorHandler.validateGearInput(name: "Test Gear", weight: "-10", category: "Clothing")
        
        switch result {
        case .success():
            XCTFail("Validation should fail with negative weight")
        case .failure(let error):
            XCTAssertTrue(error.errorDescription?.contains("Valid weight is required") == true)
        }
    }
    
    func testValidateGearInputFailureEmptyCategory() {
        let result = errorHandler.validateGearInput(name: "Test Gear", weight: "100.5", category: "")
        
        switch result {
        case .success():
            XCTFail("Validation should fail with empty category")
        case .failure(let error):
            XCTAssertTrue(error.errorDescription?.contains("Category is required") == true)
        }
    }
    
    func testValidateHikeInputSuccess() {
        let result = errorHandler.validateHikeInput(name: "Test Hike", location: "Test Location", distance: "10.5")
        
        switch result {
        case .success():
            XCTAssertTrue(true, "Validation should succeed")
        case .failure(_):
            XCTFail("Validation should not fail with valid input")
        }
    }
    
    func testValidateHikeInputSuccessWithOptionalDistance() {
        let result = errorHandler.validateHikeInput(name: "Test Hike", location: "Test Location", distance: nil)
        
        switch result {
        case .success():
            XCTAssertTrue(true, "Validation should succeed with nil distance")
        case .failure(_):
            XCTFail("Validation should not fail with nil distance")
        }
    }
    
    func testValidateHikeInputFailureEmptyName() {
        let result = errorHandler.validateHikeInput(name: "", location: "Test Location", distance: "10.5")
        
        switch result {
        case .success():
            XCTFail("Validation should fail with empty name")
        case .failure(let error):
            XCTAssertTrue(error.errorDescription?.contains("name is required") == true)
        }
    }
    
    func testValidateHikeInputFailureEmptyLocation() {
        let result = errorHandler.validateHikeInput(name: "Test Hike", location: "", distance: "10.5")
        
        switch result {
        case .success():
            XCTFail("Validation should fail with empty location")
        case .failure(let error):
            XCTAssertTrue(error.errorDescription?.contains("Location is required") == true)
        }
    }
    
    func testValidateHikeInputFailureInvalidDistance() {
        let result = errorHandler.validateHikeInput(name: "Test Hike", location: "Test Location", distance: "invalid")
        
        switch result {
        case .success():
            XCTFail("Validation should fail with invalid distance")
        case .failure(let error):
            XCTAssertTrue(error.errorDescription?.contains("Distance must be a valid number") == true)
        }
    }
    
    func testValidateHikeInputFailureNegativeDistance() {
        let result = errorHandler.validateHikeInput(name: "Test Hike", location: "Test Location", distance: "-5")
        
        switch result {
        case .success():
            XCTFail("Validation should fail with negative distance")
        case .failure(let error):
            XCTAssertTrue(error.errorDescription?.contains("Distance must be a valid number") == true)
        }
    }
    
    // MARK: - Error Presentation Tests
    
    func testPresentError() {
        let testError = PackPlannerError.validationError("Test error")
        let expectation = self.expectation(description: "Error presentation")
        
        // Verify that error presentation doesn't crash
        errorHandler.presentError(testError, on: mockViewController)
        
        // Give some time for the async presentation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 1.0, handler: nil)
    }
    
    // MARK: - Realm Error Handling Tests
    
    func testHandleRealmError() {
        let testError = NSError(domain: "TestDomain", code: 123, userInfo: [NSLocalizedDescriptionKey: "Test realm error"])
        let wrappedError = errorHandler.handleRealmError(testError, operation: "test operation")
        
        XCTAssertTrue(wrappedError.errorDescription?.contains("Failed to test operation") == true)
    }
    
    func testSafeRealmWriteSuccess() {
        let result = errorHandler.safeRealmWrite {
            return "Success"
        }
        
        switch result {
        case .success(let value):
            XCTAssertEqual(value, "Success")
        case .failure(_):
            XCTFail("Safe realm write should succeed")
        }
    }
    
    func testSafeRealmWriteFailure() {
        let result = errorHandler.safeRealmWrite {
            throw NSError(domain: "TestDomain", code: 123, userInfo: nil)
        }
        
        switch result {
        case .success(_):
            XCTFail("Safe realm write should fail")
        case .failure(let error):
            XCTAssertTrue(error.errorDescription?.contains("Failed to write operation") == true)
        }
    }
}

// MARK: - Mock Classes

class MockViewController: UIViewController {
    var presentedViewController: UIViewController?
    var presentAnimated: Bool = false
    var presentCompletion: (() -> Void)?
    
    override func present(_ viewControllerToPresent: UIViewController, animated flag: Bool, completion: (() -> Void)? = nil) {
        presentedViewController = viewControllerToPresent
        presentAnimated = flag
        presentCompletion = completion
        completion?()
    }
}