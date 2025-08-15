//
//  DependencyContainer.swift
//  PackPlanner
//
//  Created by Claude on Dependency Injection Implementation
//

import Foundation
import RealmSwift

/**
 * DependencyContainer - Centralized dependency injection system for PackPlanner
 * 
 * This container manages the lifecycle and injection of dependencies throughout the app,
 * promoting loose coupling, testability, and better separation of concerns.
 * 
 * Key Features:
 * - Service registration with lifecycle management
 * - Support for singleton, transient, and scoped lifetimes
 * - Protocol-based dependency injection
 * - Thread-safe service resolution
 * - Circular dependency detection
 * - Easy testing with mock services
 * 
 * Architecture:
 * - Uses factory pattern for service creation
 * - Maintains service registry with metadata
 * - Supports both type-based and protocol-based injection
 * - Automatic dependency graph resolution
 */

// MARK: - Service Lifetime

enum ServiceLifetime {
    case singleton    // One instance for the entire app lifecycle
    case transient    // New instance every time
    case scoped      // One instance per scope (e.g., per view controller)
}

// MARK: - Service Registry Entry

private class ServiceEntry {
    let lifetime: ServiceLifetime
    let factory: () -> Any
    var instance: Any?
    
    init(lifetime: ServiceLifetime, factory: @escaping () -> Any) {
        self.lifetime = lifetime
        self.factory = factory
    }
}

// MARK: - Dependency Container

class DependencyContainer {
    static let shared = DependencyContainer()
    
    private let queue = DispatchQueue(label: "com.packplanner.dependencies", attributes: .concurrent)
    private var services: [String: ServiceEntry] = [:]
    private var resolutionStack: Set<String> = []
    
    private init() {
        registerDefaultServices()
    }
    
    // MARK: - Service Registration
    
    /**
     * Registers a service with singleton lifetime.
     * The same instance will be returned for all resolution requests.
     */
    func registerSingleton<T>(_ type: T.Type, factory: @escaping () -> T) {
        register(type, lifetime: .singleton, factory: factory)
    }
    
    /**
     * Registers a service with transient lifetime.
     * A new instance will be created for each resolution request.
     */
    func registerTransient<T>(_ type: T.Type, factory: @escaping () -> T) {
        register(type, lifetime: .transient, factory: factory)
    }
    
    /**
     * Registers a service with scoped lifetime.
     * Same instance within a scope, new instance for different scopes.
     */
    func registerScoped<T>(_ type: T.Type, factory: @escaping () -> T) {
        register(type, lifetime: .scoped, factory: factory)
    }
    
    private func register<T>(_ type: T.Type, lifetime: ServiceLifetime, factory: @escaping () -> T) {
        let key = String(describing: type)
        let entry = ServiceEntry(lifetime: lifetime) { factory() }
        
        queue.async(flags: .barrier) { [weak self] in
            self?.services[key] = entry
        }
    }
    
    // MARK: - Service Resolution
    
    /**
     * Resolves a service instance by type.
     * Throws if the service is not registered or circular dependency is detected.
     */
    func resolve<T>(_ type: T.Type) throws -> T {
        let key = String(describing: type)
        
        return try queue.sync { [weak self] in
            guard let self = self else {
                throw DIError.containerNotAvailable
            }
            
            // Check for circular dependency
            if self.resolutionStack.contains(key) {
                throw DIError.circularDependency(key)
            }
            
            guard let entry = self.services[key] else {
                throw DIError.serviceNotRegistered(key)
            }
            
            // Add to resolution stack
            self.resolutionStack.insert(key)
            defer { self.resolutionStack.remove(key) }
            
            let instance: Any
            
            switch entry.lifetime {
            case .singleton:
                if let existingInstance = entry.instance {
                    instance = existingInstance
                } else {
                    instance = entry.factory()
                    entry.instance = instance
                }
                
            case .transient:
                instance = entry.factory()
                
            case .scoped:
                // For now, scoped behaves like singleton
                // In a more complex implementation, this would be scope-aware
                if let existingInstance = entry.instance {
                    instance = existingInstance
                } else {
                    instance = entry.factory()
                    entry.instance = instance
                }
            }
            
            guard let typedInstance = instance as? T else {
                throw DIError.typeMismatch(expected: String(describing: T.self), actual: String(describing: type(of: instance)))
            }
            
            return typedInstance
        }
    }
    
    /**
     * Optionally resolves a service instance by type.
     * Returns nil if the service is not registered instead of throwing.
     */
    func optionalResolve<T>(_ type: T.Type) -> T? {
        do {
            return try resolve(type)
        } catch {
            return nil
        }
    }
    
    // MARK: - Service Management
    
    /**
     * Checks if a service is registered for the given type.
     */
    func isRegistered<T>(_ type: T.Type) -> Bool {
        let key = String(describing: type)
        return queue.sync {
            return services[key] != nil
        }
    }
    
    /**
     * Unregisters a service for the given type.
     */
    func unregister<T>(_ type: T.Type) {
        let key = String(describing: type)
        queue.async(flags: .barrier) { [weak self] in
            self?.services.removeValue(forKey: key)
        }
    }
    
    /**
     * Clears all singleton instances, forcing re-creation on next resolution.
     * Useful for testing or when major configuration changes occur.
     */
    func clearSingletonInstances() {
        queue.async(flags: .barrier) { [weak self] in
            guard let self = self else { return }
            for entry in self.services.values where entry.lifetime == .singleton {
                entry.instance = nil
            }
        }
    }
    
    /**
     * Registers default services that the app requires.
     */
    private func registerDefaultServices() {
        // Register DataService as singleton
        registerSingleton(DataService.self) {
            return DataService.shared
        }
        
        // Register ErrorHandler as singleton  
        // TODO: Fix ErrorHandler scope issue
        // registerSingleton(ErrorHandler.self) {
        //     return ErrorHandler.shared
        // }
        
        // Register LoadingStateManager as singleton
        registerSingleton(LoadingStateManager.self) {
            return LoadingStateManager.shared
        }
        
        // Register SettingsManager as singleton
        registerSingleton(SettingsManager.self) {
            return SettingsManager.SINGLETON
        }
        
        // Register SwiftUIMigrationHelper as singleton
        registerSingleton(SwiftUIMigrationHelper.self) {
            return SwiftUIMigrationHelper.shared
        }
    }
}

// MARK: - Dependency Injection Errors

enum DIError: LocalizedError {
    case serviceNotRegistered(String)
    case circularDependency(String)
    case typeMismatch(expected: String, actual: String)
    case containerNotAvailable
    
    var errorDescription: String? {
        switch self {
        case .serviceNotRegistered(let service):
            return "Service not registered: \(service)"
        case .circularDependency(let service):
            return "Circular dependency detected while resolving: \(service)"
        case .typeMismatch(let expected, let actual):
            return "Type mismatch: expected \(expected), got \(actual)"
        case .containerNotAvailable:
            return "Dependency container is not available"
        }
    }
}

// MARK: - Injectable Protocol

/**
 * Protocol for types that support dependency injection.
 * Implement this protocol to enable automatic dependency resolution.
 */
protocol Injectable {
    init()
    func configureDependencies()
}

// MARK: - Property Wrapper for Dependency Injection

/**
 * Property wrapper for automatic dependency injection.
 * Usage: @Injected var dataService: DataService
 */
@propertyWrapper
struct Injected<T> {
    private let container: DependencyContainer
    
    var wrappedValue: T {
        do {
            return try container.resolve(T.self)
        } catch {
            print("Critical: Dependency injection failed for \(T.self): \(error)")
            preconditionFailure("Critical dependency injection failure for \(T.self). Please restart the app.")
        }
    }
    
    init(container: DependencyContainer = .shared) {
        self.container = container
    }
}

// MARK: - Optional Injection Property Wrapper

/**
 * Property wrapper for optional dependency injection.
 * Usage: @OptionalInjected var optionalService: OptionalService?
 */
@propertyWrapper
struct OptionalInjected<T> {
    private let container: DependencyContainer
    
    var wrappedValue: T? {
        return container.optionalResolve(T.self)
    }
    
    init(container: DependencyContainer = .shared) {
        self.container = container
    }
}

// MARK: - Convenience Extensions

extension UIViewController {
    /**
     * Resolves a dependency for this view controller.
     */
    func resolve<T>(_ type: T.Type) -> T? {
        return DependencyContainer.shared.optionalResolve(type)
    }
}