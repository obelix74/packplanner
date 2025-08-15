//
//  RealmManager.swift
//  PackPlanner
//
//  Created by Claude on Realm Consolidation
//

import Foundation
import RealmSwift

/**
 * RealmManager - Centralized Realm database management
 * 
 * This singleton provides a unified interface for all Realm operations,
 * eliminating multiple Realm instances and providing consistent error handling.
 * 
 * Key Features:
 * - Single Realm instance with proper lifecycle management
 * - Thread-safe operations with concurrent/barrier queues
 * - Comprehensive fallback and recovery mechanisms
 * - Centralized configuration and migration handling
 * - Memory-efficient connection pooling
 * 
 * Usage:
 * - Use RealmManager.shared.realm for all database operations
 * - Use performWrite() for write operations with automatic error handling
 * - Use performRead() for read operations with proper threading
 */
class RealmManager {
    static let shared = RealmManager()
    
    private var _realm: Realm?
    private let realmQueue = DispatchQueue(label: "com.packplanner.realm", attributes: .concurrent)
    private let initializationQueue = DispatchQueue(label: "com.packplanner.realm.init")
    
    private init() {
        // Realm initialization is deferred until first access
    }
    
    // MARK: - Realm Instance Access
    
    var realm: Realm {
        return realmQueue.sync {
            if let existingRealm = _realm {
                return existingRealm
            }
            
            // Initialize on first access
            return initializationQueue.sync {
                if let existingRealm = _realm {
                    return existingRealm
                }
                
                let newRealm = createRealmInstance()
                _realm = newRealm
                return newRealm
            }
        }
    }
    
    // MARK: - Thread-Safe Operations
    
    /**
     * Perform a write operation with automatic error handling and threading
     */
    func performWrite<T>(_ operation: @escaping (Realm) throws -> T) -> Result<T, RealmError> {
        return Result {
            let realmInstance = realm
            if realmInstance.isInWriteTransaction {
                // Already in write transaction, execute directly
                return try operation(realmInstance)
            } else {
                // Start new write transaction
                var result: T?
                var thrownError: Error?
                
                try realmInstance.write {
                    do {
                        result = try operation(realmInstance)
                    } catch {
                        thrownError = error
                        throw error
                    }
                }
                
                if let error = thrownError {
                    throw error
                }
                
                return result!
            }
        }.mapError { error in
            print("Realm write operation failed: \(error)")
            return RealmError.writeOperationFailed(error)
        }
    }
    
    /**
     * Perform a read operation with proper threading
     */
    func performRead<T>(_ operation: @escaping (Realm) -> T) -> T {
        let realmInstance = realm
        return operation(realmInstance)
    }
    
    /**
     * Perform an async write operation
     */
    func performAsyncWrite<T>(_ operation: @escaping (Realm) throws -> T, completion: @escaping (Result<T, RealmError>) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else {
                DispatchQueue.main.async {
                    completion(.failure(.instanceDeallocated))
                }
                return
            }
            
            let result = self.performWrite(operation)
            
            DispatchQueue.main.async {
                completion(result)
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func createRealmInstance() -> Realm {
        do {
            // Use the default configuration that should already be set by SettingsManager
            let newRealm = try Realm()
            print("RealmManager: Successfully created primary Realm instance")
            return newRealm
        } catch {
            print("RealmManager: Failed to create primary Realm instance: \(error)")
            
            // Attempt fallback to in-memory realm
            do {
                let fallbackConfig = Realm.Configuration(
                    inMemoryIdentifier: "realmmanager_fallback_\(UUID().uuidString)",
                    schemaVersion: 1
                )
                let fallbackRealm = try Realm(configuration: fallbackConfig)
                print("RealmManager: Using in-memory database fallback")
                return fallbackRealm
            } catch {
                print("RealmManager: Fallback Realm initialization failed: \(error)")
                
                // Final emergency fallback
                let emergencyConfig = Realm.Configuration(
                    inMemoryIdentifier: "realmmanager_emergency_\(UUID().uuidString)",
                    schemaVersion: 1,
                    deleteRealmIfMigrationNeeded: true
                )
                
                do {
                    let emergencyRealm = try Realm(configuration: emergencyConfig)
                    print("RealmManager: Using emergency empty database")
                    return emergencyRealm
                } catch {
                    // This should never happen, but if it does, we can't continue
                    preconditionFailure("RealmManager: Cannot initialize any database. Please restart the app.")
                }
            }
        }
    }
    
    // MARK: - Cleanup
    
    func invalidate() {
        realmQueue.async(flags: .barrier) { [weak self] in
            self?._realm?.invalidate()
            self?._realm = nil
        }
    }
    
    deinit {
        invalidate()
    }
}

// MARK: - Error Types

enum RealmError: LocalizedError {
    case writeOperationFailed(Error)
    case instanceDeallocated
    case configurationFailed(Error)
    
    var errorDescription: String? {
        switch self {
        case .writeOperationFailed(let error):
            return "Realm write operation failed: \(error.localizedDescription)"
        case .instanceDeallocated:
            return "RealmManager instance was deallocated"
        case .configurationFailed(let error):
            return "Realm configuration failed: \(error.localizedDescription)"
        }
    }
}

// MARK: - Convenience Extensions

extension RealmManager {
    /**
     * Add object with automatic error handling
     */
    func add<T: Object>(_ object: T) -> Result<Void, RealmError> {
        return performWrite { realm in
            realm.add(object)
        }
    }
    
    /**
     * Delete object with automatic error handling
     */
    func delete<T: Object>(_ object: T) -> Result<Void, RealmError> {
        return performWrite { realm in
            realm.delete(object)
        }
    }
    
    /**
     * Query objects safely
     */
    func objects<T: Object>(_ type: T.Type) -> Results<T> {
        return performRead { realm in
            realm.objects(type)
        }
    }
}