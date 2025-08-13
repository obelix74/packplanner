//
//  ErrorHandler.swift
//  PackPlanner
//
//  Created by Claude on Error Handling Standardization
//

import UIKit
import RealmSwift

/**
 * ErrorHandler - Centralized error handling system for PackPlanner
 * 
 * This utility provides consistent error handling patterns throughout the app,
 * standardizing how errors are logged, presented to users, and recovered from.
 * 
 * Key Features:
 * - Typed error system with specific error categories
 * - Centralized error logging with context information
 * - User-friendly error presentation with recovery suggestions
 * - Realm database error handling with safe fallbacks
 * - Input validation with descriptive error messages
 * 
 * Usage:
 * - Use PackPlannerError enum for application-specific errors
 * - Call ErrorHandler.shared methods for consistent error handling
 * - Use UIViewController extension methods for convenient error presentation
 * - Wrap Realm operations with safeRealmWrite for automatic error handling
 */

// MARK: - Error Types

enum PackPlannerError: LocalizedError {
    case databaseError(String)
    case validationError(String)
    case networkError(String)
    case fileSystemError(String)
    case userInputError(String)
    case unknownError(String)
    
    var errorDescription: String? {
        switch self {
        case .databaseError(let message):
            return "Database Error: \(message)"
        case .validationError(let message):
            return "Validation Error: \(message)"
        case .networkError(let message):
            return "Network Error: \(message)"
        case .fileSystemError(let message):
            return "File System Error: \(message)"
        case .userInputError(let message):
            return "Input Error: \(message)"
        case .unknownError(let message):
            return "Unknown Error: \(message)"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .databaseError:
            return "Please try restarting the app. If the problem persists, contact support."
        case .validationError:
            return "Please check your input and try again."
        case .networkError:
            return "Please check your internet connection and try again."
        case .fileSystemError:
            return "Please free up storage space and try again."
        case .userInputError:
            return "Please correct the highlighted fields and try again."
        case .unknownError:
            return "Please try again. If the problem persists, contact support."
        }
    }
}

// MARK: - Error Handler

class ErrorHandler {
    static let shared = ErrorHandler()
    
    private init() {}
    
    // MARK: - Error Logging
    
    func logError(_ error: Error, context: String? = nil, file: String = #file, function: String = #function, line: Int = #line) {
        let fileName = (file as NSString).lastPathComponent
        let contextInfo = context != nil ? " Context: \(context!)" : ""
        let errorMessage = "ERROR in \(fileName):\(function):\(line) - \(error.localizedDescription)\(contextInfo)"
        
        print("📱 \(errorMessage)")
        
        // In production, you might want to log to a crash reporting service
        // CrashReporting.log(errorMessage)
    }
    
    // MARK: - User Facing Error Presentation
    
    func presentError(_ error: Error, on viewController: UIViewController, context: String? = nil) {
        logError(error, context: context)
        
        DispatchQueue.main.async {
            let alert = self.createErrorAlert(for: error)
            viewController.present(alert, animated: true)
        }
    }
    
    func presentErrorWithCompletion(_ error: Error, on viewController: UIViewController, completion: @escaping () -> Void) {
        logError(error)
        
        DispatchQueue.main.async {
            let alert = self.createErrorAlert(for: error, completion: completion)
            viewController.present(alert, animated: true)
        }
    }
    
    // MARK: - Realm Error Handling
    
    func handleRealmError(_ error: Error, operation: String) -> PackPlannerError {
        logError(error, context: "Realm operation: \(operation)")
        
        if error is Realm.Error {
            return .databaseError("Failed to \(operation). The database may be corrupted.")
        } else {
            return .databaseError("Failed to \(operation): \(error.localizedDescription)")
        }
    }
    
    func safeRealmWrite<T>(_ operation: () throws -> T, errorContext: String = "write operation") -> Result<T, PackPlannerError> {
        do {
            let result = try operation()
            return .success(result)
        } catch {
            let wrappedError = handleRealmError(error, operation: errorContext)
            return .failure(wrappedError)
        }
    }
    
    // MARK: - Validation Helpers
    
    func validateGearInput(name: String?, weight: String?, category: String?) -> Result<Void, PackPlannerError> {
        guard let name = name, !name.trimmingCharacters(in: .whitespaces).isEmpty else {
            return .failure(.userInputError("Gear name is required"))
        }
        
        guard let weightStr = weight, !weightStr.isEmpty,
              let _ = Double(weightStr), Double(weightStr)! > 0 else {
            return .failure(.userInputError("Valid weight is required"))
        }
        
        guard let category = category, !category.trimmingCharacters(in: .whitespaces).isEmpty else {
            return .failure(.userInputError("Category is required"))
        }
        
        return .success(())
    }
    
    func validateHikeInput(name: String?, location: String?, distance: String?) -> Result<Void, PackPlannerError> {
        guard let name = name, !name.trimmingCharacters(in: .whitespaces).isEmpty else {
            return .failure(.userInputError("Hike name is required"))
        }
        
        guard let location = location, !location.trimmingCharacters(in: .whitespaces).isEmpty else {
            return .failure(.userInputError("Location is required"))
        }
        
        if let distanceStr = distance, !distanceStr.isEmpty {
            guard let _ = Double(distanceStr), Double(distanceStr)! >= 0 else {
                return .failure(.userInputError("Distance must be a valid number"))
            }
        }
        
        return .success(())
    }
    
    // MARK: - Private Methods
    
    private func createErrorAlert(for error: Error, completion: (() -> Void)? = nil) -> UIAlertController {
        let title: String
        let message: String
        
        if let packPlannerError = error as? PackPlannerError {
            title = "Error"
            message = packPlannerError.localizedDescription + "\n\n" + (packPlannerError.recoverySuggestion ?? "")
        } else {
            title = "Unexpected Error"
            message = error.localizedDescription
        }
        
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        let okAction = UIAlertAction(title: "OK", style: .default) { _ in
            completion?()
        }
        alert.addAction(okAction)
        
        return alert
    }
}

// MARK: - Convenience Extensions

extension UIViewController {
    func handleError(_ error: Error, context: String? = nil) {
        ErrorHandler.shared.presentError(error, on: self, context: context)
    }
    
    func handleErrorWithCompletion(_ error: Error, completion: @escaping () -> Void) {
        ErrorHandler.shared.presentErrorWithCompletion(error, on: self, completion: completion)
    }
    
    func showSuccessMessage(_ message: String) {
        DispatchQueue.main.async {
            let alert = UIAlertController(title: "Success", message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            self.present(alert, animated: true)
        }
    }
}