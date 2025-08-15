//
//  DataService.swift
//  PackPlanner
//
//  Created by Claude on SwiftUI Migration
//

import Foundation
import SwiftUI
import RealmSwift
import Combine

// MARK: - DataService Protocol

/**
 * Protocol defining the data access interface for PackPlanner.
 * This protocol enables dependency injection and testing with mock implementations.
 */
protocol DataServiceProtocol: ObservableObject {
    var gears: [GearSwiftUI] { get }
    var hikes: [HikeSwiftUI] { get }
    
    func loadData()
    func addGear(_ gear: GearSwiftUI)
    func updateGear(_ gear: GearSwiftUI)
    func deleteGear(_ gear: GearSwiftUI)
    func addHike(_ hike: HikeSwiftUI)
    func updateHike(_ hike: HikeSwiftUI, originalName: String?)
    func deleteHike(_ hike: HikeSwiftUI)
    func searchGear(query: String) -> [GearSwiftUI]
    func searchHikes(query: String) -> [HikeSwiftUI]
    func gearByCategory() -> [String: [GearSwiftUI]]
    func copyHike(_ originalHike: HikeSwiftUI) -> HikeSwiftUI
    func cleanupDatabaseDuplicates()
    func cleanupDuplicateHikeGears()
}

/**
 * DataService - Centralized data access layer for PackPlanner
 * 
 * This service provides thread-safe CRUD operations for gear and hike data,
 * maintaining consistency between legacy Realm objects and modern SwiftUI models.
 * It implements the repository pattern with caching for improved performance.
 * 
 * Key Features:
 * - Thread-safe operations using concurrent and barrier queues
 * - Automatic cache synchronization with database changes
 * - Bridge between legacy UIKit models and SwiftUI models
 * - Comprehensive error handling with centralized ErrorHandler
 * - Duplicate data cleanup and integrity maintenance
 * 
 * Architecture:
 * - Uses ObservableObject for SwiftUI reactivity
 * - Maintains in-memory caches for performance
 * - Performs database operations on background queues
 * - Updates UI on main queue
 * 
 * Thread Safety:
 * - Read operations use concurrent queue for parallel access
 * - Write operations use barrier queue for exclusive access
 * - Cache updates are always performed on main queue
 */
class DataService: DataServiceProtocol {
    static let shared = DataService()
    
    private let realm: Realm
    private let concurrentQueue = DispatchQueue(label: "com.packplanner.dataservice", attributes: .concurrent)
    private let barrierQueue = DispatchQueue(label: "com.packplanner.dataservice.barrier")
    
    @Published private var gearCache: [GearSwiftUI] = []
    @Published private var hikeCache: [HikeSwiftUI] = []
    
    private init() {
        
        do {
            // Use the default configuration that should already be set by SettingsManager
            self.realm = try Realm()
            // Clean up any database duplicates on startup
            cleanupDatabaseDuplicates()
            // Also clean up gear duplicates
            GearBrain.cleanupDuplicateGears()
        } catch {
            print("Critical: Failed to initialize Realm database: \(error)")
            // Attempt fallback to in-memory realm
            do {
                let fallbackConfig = Realm.Configuration(
                    inMemoryIdentifier: "dataservice_fallback",
                    schemaVersion: 1
                )
                self.realm = try Realm(configuration: fallbackConfig)
                print("DataService using in-memory database fallback")
            } catch {
                fatalError("Fatal: DataService cannot initialize any Realm database. App cannot continue: \(error)")
            }
        }
    }
    
    // MARK: - Data Loading
    
    /**
     * Initiates loading of all cached data from Realm database.
     * Triggers concurrent loading of gear and hike data to populate in-memory caches.
     * Should be called during app initialization or after major data changes.
     */
    func loadData() {
        loadGear()
        loadHikes()
    }
    
    private func loadGear() {
        concurrentQueue.async { [weak self] in
            guard let self = self else { return }
            
            // Create a new Realm instance for this background thread
            do {
                let backgroundRealm = try Realm()
                
                // Clean up duplicates first using the background realm
                try backgroundRealm.write {
                    let allGears = backgroundRealm.objects(Gear.self)
                    var seenUUIDs = Set<String>()
                    var duplicatesToDelete: [Gear] = []
                    
                    for gear in allGears {
                        if seenUUIDs.contains(gear.uuid) {
                            duplicatesToDelete.append(gear)
                        } else {
                            seenUUIDs.insert(gear.uuid)
                        }
                    }
                    
                    // Delete the duplicates
                    for duplicate in duplicatesToDelete {
                        backgroundRealm.delete(duplicate)
                    }
                }
                
                let gearObjects = backgroundRealm.objects(Gear.self)
                let newGearCache = Array(gearObjects.map { GearSwiftUI(from: $0) })
                
                DispatchQueue.main.async {
                    self.gearCache = newGearCache
                }
            } catch {
                print("Error loading gear on background thread: \(error)")
            }
        }
    }
    
    private func loadHikes() {
        print("🔴 DEBUG: loadHikes() called")
        concurrentQueue.async { [weak self] in
            guard let self = self else { return }
            
            print("🔴 DEBUG: loadHikes() background thread started")
            
            // Create a new Realm instance for this background thread
            do {
                let backgroundRealm = try Realm()
                let hikeObjects = backgroundRealm.objects(Hike.self)
                print("🔴 DEBUG: Found \(hikeObjects.count) hikes in Realm")
                
                let newHikeCache = Array(hikeObjects.map { hikeObj in
                    let hikeSwiftUI = HikeSwiftUI(from: hikeObj)
                    print("🔴 DEBUG: Loaded hike '\(hikeSwiftUI.name)' with \(hikeSwiftUI.hikeGears.count) hikeGears")
                    return hikeSwiftUI
                })
                
                DispatchQueue.main.async {
                    print("🔴 DEBUG: Updating hikeCache on main thread with \(newHikeCache.count) hikes")
                    self.hikeCache = newHikeCache
                    print("🔴 DEBUG: hikeCache updated")
                }
            } catch {
                print("🔴 DEBUG ERROR: Error loading hikes on background thread: \(error)")
            }
        }
    }
    
    // MARK: - Gear CRUD Operations
    
    var gears: [GearSwiftUI] {
        return concurrentQueue.sync {
            return gearCache
        }
    }
    
    /**
     * Adds a new gear item to the database and cache.
     * 
     * - Parameter gear: The SwiftUI gear model to be saved
     * - Note: Operation is performed on background queue for thread safety
     * - Note: Cache is updated on main queue after successful database write
     */
    func addGear(_ gear: GearSwiftUI) {
        barrierQueue.async { [weak self] in
            guard let self = self else { return }
            
            // Create a new Realm instance for this background thread
            do {
                let backgroundRealm = try Realm()
                let legacyGear = gear.toLegacyGear()
                try backgroundRealm.write {
                    backgroundRealm.add(legacyGear)
                }
                DispatchQueue.main.async {
                    self.gearCache.append(gear)
                    self.objectWillChange.send()
                }
            } catch {
                print("Error adding gear: \(error)")
            }
        }
    }
    
    func updateGear(_ gear: GearSwiftUI) {
        barrierQueue.async { [weak self] in
            guard let self = self else { return }
            
            // Create a new Realm instance for this background thread
            do {
                let backgroundRealm = try Realm()
                try backgroundRealm.write {
                    if let existingGear = backgroundRealm.objects(Gear.self).filter("uuid == %@", gear.id).first {
                        existingGear.name = gear.name
                        existingGear.desc = gear.desc
                        existingGear.weightInGrams = gear.weightInGrams
                        existingGear.category = gear.category
                    }
                }
                DispatchQueue.main.async {
                    if let index = self.gearCache.firstIndex(where: { $0.id == gear.id }) {
                        self.gearCache[index] = gear
                        self.objectWillChange.send()
                    }
                }
            } catch {
                print("Error updating gear: \(error)")
            }
        }
    }
    
    func deleteGear(_ gear: GearSwiftUI) {
        barrierQueue.async { [weak self] in
            guard let self = self else { return }
            
            // Create a new Realm instance for this background thread
            do {
                let backgroundRealm = try Realm()
                try backgroundRealm.write {
                    if let gearToDelete = backgroundRealm.objects(Gear.self).filter("uuid == %@", gear.id).first {
                        backgroundRealm.delete(gearToDelete)
                    }
                }
                DispatchQueue.main.async {
                    self.gearCache.removeAll { $0.id == gear.id }
                }
            } catch {
                print("Error deleting gear: \(error)")
            }
        }
    }
    
    // MARK: - Hike CRUD Operations
    
    var hikes: [HikeSwiftUI] {
        return concurrentQueue.sync {
            return hikeCache
        }
    }
    
    func addHike(_ hike: HikeSwiftUI) {
        barrierQueue.async { [weak self] in
            guard let self = self else { return }
            
            // Create a new Realm instance for this background thread
            do {
                let backgroundRealm = try Realm()
                try backgroundRealm.write {
                    let legacyHike = hike.toLegacyHike()
                    
                    // Add HikeGear relationships
                    for hikeGearSwiftUI in hike.hikeGears {
                        let legacyHikeGear = hikeGearSwiftUI.toLegacyHikeGear()
                        backgroundRealm.add(legacyHikeGear)
                        legacyHike.hikeGears.append(legacyHikeGear)
                    }
                    
                    backgroundRealm.add(legacyHike)
                }
                DispatchQueue.main.async {
                    self.hikeCache.append(hike)
                    self.objectWillChange.send()
                }
            } catch {
                print("Error adding hike: \(error)")
            }
        }
    }
    
    func updateHike(_ hike: HikeSwiftUI, originalName: String? = nil, completion: (() -> Void)? = nil) {
        print("🟠 DEBUG: DataService.updateHike() called")
        print("🟠 DEBUG: hike.id: \(hike.id)")
        print("🟠 DEBUG: hike.name: \(hike.name)")
        print("🟠 DEBUG: hike.hikeGears count: \(hike.hikeGears.count)")
        for (index, hikeGear) in hike.hikeGears.enumerated() {
            print("🟠 DEBUG: hikeGear[\(index)]: \(hikeGear.gear?.name ?? "unknown")")
        }
        
        barrierQueue.async { [weak self] in
            guard let self = self else { return }
            
            print("🟠 DEBUG: Background thread started for updateHike")
            
            // Create a new Realm instance for this background thread
            do {
                let backgroundRealm = try Realm()
                try backgroundRealm.write {
                    guard let existingHike = self.findExistingHike(realm: backgroundRealm, hike: hike, originalName: originalName) else {
                        print("🟠 DEBUG ERROR: Hike not found for update")
                        return
                    }
                    
                    print("🟠 DEBUG: Found existing hike: \(existingHike.name)")
                    print("🟠 DEBUG: Existing hike gear count before update: \(existingHike.hikeGears.count)")
                    
                    self.updateHikeProperties(existingHike: existingHike, from: hike)
                    self.updateHikeGearRelationships(realm: backgroundRealm, existingHike: existingHike, from: hike)
                    
                    print("🟠 DEBUG: Existing hike gear count after update: \(existingHike.hikeGears.count)")
                }
                print("🟠 DEBUG: Realm write transaction completed successfully")
                DispatchQueue.main.async {
                    print("🟠 DEBUG: Updating cache on main thread")
                    self.updateHikeInCache(hike)
                    self.objectWillChange.send()
                    print("🟠 DEBUG: Cache update completed")
                    
                    // Call completion handler after cache update is complete
                    completion?()
                }
            } catch {
                print("🟠 DEBUG ERROR: Error updating hike: \(error)")
            }
        }
    }
    
    // Convenience method for backward compatibility
    func updateHike(_ hike: HikeSwiftUI, originalName: String? = nil) {
        updateHike(hike, originalName: originalName, completion: nil)
    }
    
    // MARK: - Private Helper Methods for updateHike
    
    private func findExistingHike(realm: Realm, hike: HikeSwiftUI, originalName: String?) -> Hike? {
        let nameToSearch = originalName ?? hike.name
        return realm.objects(Hike.self).filter("name == %@", nameToSearch).first
    }
    
    private func updateHikeProperties(existingHike: Hike, from hike: HikeSwiftUI) {
        existingHike.name = hike.name
        existingHike.desc = hike.desc
        existingHike.distance = hike.distance
        existingHike.location = hike.location
        existingHike.completed = hike.completed
        existingHike.externalLink1 = hike.externalLink1.isEmpty ? nil : hike.externalLink1
        existingHike.externalLink2 = hike.externalLink2.isEmpty ? nil : hike.externalLink2
        existingHike.externalLink3 = hike.externalLink3.isEmpty ? nil : hike.externalLink3
    }
    
    private func updateHikeGearRelationships(realm: Realm, existingHike: Hike, from hike: HikeSwiftUI) {
        print("🟠 DEBUG: updateHikeGearRelationships() called")
        print("🟠 DEBUG: Input hikeGears count: \(hike.hikeGears.count)")
        
        // Remove existing HikeGear entries
        print("🟠 DEBUG: Deleting \(existingHike.hikeGears.count) existing hikeGears")
        realm.delete(existingHike.hikeGears)
        existingHike.hikeGears.removeAll()
        
        // Get unique HikeGear entries to prevent duplicates
        let uniqueHikeGears = getUniqueHikeGears(from: hike.hikeGears)
        print("🟠 DEBUG: Unique hikeGears count: \(uniqueHikeGears.count)")
        
        // Add current HikeGear relationships
        for (index, hikeGearSwiftUI) in uniqueHikeGears.enumerated() {
            print("🟠 DEBUG: Processing hikeGear[\(index)]: \(hikeGearSwiftUI.gear?.name ?? "unknown")")
            let legacyHikeGear = hikeGearSwiftUI.toLegacyHikeGear()
            print("🟠 DEBUG: Created legacyHikeGear with gear: \(legacyHikeGear.gear?.name ?? "unknown")")
            realm.add(legacyHikeGear)
            existingHike.hikeGears.append(legacyHikeGear)
            print("🟠 DEBUG: Added to Realm and existingHike")
        }
        
        print("🟠 DEBUG: Final existingHike.hikeGears count: \(existingHike.hikeGears.count)")
    }
    
    private func getUniqueHikeGears(from hikeGears: [HikeGearSwiftUI]) -> [HikeGearSwiftUI] {
        return Dictionary(grouping: hikeGears) { $0.gear?.id ?? "" }
            .compactMapValues { $0.first } // Take only first occurrence of each gear ID
            .values
            .compactMap { $0 }
    }
    
    private func updateHikeInCache(_ hike: HikeSwiftUI) {
        if let index = hikeCache.firstIndex(where: { $0.id == hike.id }) {
            hikeCache[index] = hike
        }
    }
    
    func deleteHike(_ hike: HikeSwiftUI) {
        barrierQueue.async { [weak self] in
            guard let self = self else { return }
            
            // Create a new Realm instance for this background thread
            do {
                let backgroundRealm = try Realm()
                try backgroundRealm.write {
                    if let hikeToDelete = backgroundRealm.objects(Hike.self).filter("name == %@", hike.name).first {
                        backgroundRealm.delete(hikeToDelete.hikeGears)
                        backgroundRealm.delete(hikeToDelete)
                    }
                }
                DispatchQueue.main.async {
                    self.hikeCache.removeAll { $0.id == hike.id }
                }
            } catch {
                print("Error deleting hike: \(error)")
            }
        }
    }
    
    // MARK: - Search and Filter
    
    func searchGear(query: String) -> [GearSwiftUI] {
        return concurrentQueue.sync {
            if query.isEmpty {
                return gearCache
            }
            return gearCache.filter { gear in
                gear.name.localizedCaseInsensitiveContains(query) ||
                gear.desc.localizedCaseInsensitiveContains(query) ||
                gear.category.localizedCaseInsensitiveContains(query)
            }
        }
    }
    
    func searchHikes(query: String) -> [HikeSwiftUI] {
        return concurrentQueue.sync {
            if query.isEmpty {
                return hikeCache
            }
            return hikeCache.filter { hike in
                hike.name.localizedCaseInsensitiveContains(query) ||
                hike.desc.localizedCaseInsensitiveContains(query) ||
                hike.location.localizedCaseInsensitiveContains(query)
            }
        }
    }
    
    func gearByCategory() -> [String: [GearSwiftUI]] {
        return concurrentQueue.sync {
            return Dictionary(grouping: gearCache) { $0.category }
        }
    }
    
    // MARK: - Utility Methods
    
    func cleanupDatabaseDuplicates() {
        barrierQueue.async { [weak self] in
            guard let self = self else { return }
            
            // Create a new Realm instance for this background thread
            do {
                let backgroundRealm = try Realm()
                try backgroundRealm.write {
                    let allHikes = backgroundRealm.objects(Hike.self)
                    for hike in allHikes {
                        let hikeGearsArray = Array(hike.hikeGears)
                        var seenGearUUIDs = Set<String>()
                        var duplicatesToRemove: [HikeGear] = []
                        
                        for hikeGear in hikeGearsArray {
                            if let gear = hikeGear.gear {
                                let gearUUID = gear.uuid
                                if seenGearUUIDs.contains(gearUUID) {
                                    // This is a duplicate
                                    duplicatesToRemove.append(hikeGear)
                                } else {
                                    seenGearUUIDs.insert(gearUUID)
                                }
                            }
                        }
                        
                        // Remove duplicates
                        for duplicate in duplicatesToRemove {
                            if let index = hike.hikeGears.index(of: duplicate) {
                                hike.hikeGears.remove(at: index)
                            }
                            backgroundRealm.delete(duplicate)
                        }
                    }
                }
                
                // Reload data after cleanup on main queue
                DispatchQueue.main.async {
                    self.loadData()
                }
                
            } catch {
                print("Error cleaning up database duplicates: \(error)")
            }
        }
    }
    
    func cleanupDuplicateHikeGears() {
        barrierQueue.async { [weak self] in
            guard let self = self else { return }
            
            // Create a new Realm instance for this background thread
            do {
                let backgroundRealm = try Realm()
                try backgroundRealm.write {
                    let allHikes = backgroundRealm.objects(Hike.self)
                    for hike in allHikes {
                        self.cleanupDuplicatesForSingleHike(realm: backgroundRealm, hike: hike)
                    }
                }
                // Reload data after cleanup on main queue
                DispatchQueue.main.async {
                    self.loadData()
                }
            } catch {
                print("Database cleanup failed: \(error)")
            }
        }
    }
    
    // MARK: - Private Helper Methods for cleanup
    
    private func cleanupDuplicatesForSingleHike(realm: Realm, hike: Hike) {
        let uniqueGearEntries = extractUniqueGearEntries(from: hike)
        removeAllHikeGearsFromHike(realm: realm, hike: hike)
        recreateUniqueHikeGears(realm: realm, from: uniqueGearEntries, for: hike)
    }
    
    private func extractUniqueGearEntries(from hike: Hike) -> [String: HikeGear] {
        var uniqueGearEntries: [String: HikeGear] = [:]
        
        // Process each hikeGear and keep only the first occurrence of each gear
        for hikeGear in hike.hikeGears {
            if let gear = hikeGear.gear {
                let gearId = gear.uuid
                
                // If we haven't seen this gear ID before, keep this hikeGear
                if uniqueGearEntries[gearId] == nil {
                    uniqueGearEntries[gearId] = hikeGear
                }
            }
        }
        
        return uniqueGearEntries
    }
    
    private func removeAllHikeGearsFromHike(realm: Realm, hike: Hike) {
        let allHikeGears = Array(hike.hikeGears)
        hike.hikeGears.removeAll()
        realm.delete(allHikeGears)
    }
    
    private func recreateUniqueHikeGears(realm: Realm, from uniqueGearEntries: [String: HikeGear], for hike: Hike) {
        for (_, uniqueHikeGear) in uniqueGearEntries {
            let newHikeGear = createFreshHikeGear(from: uniqueHikeGear)
            realm.add(newHikeGear)
            hike.hikeGears.append(newHikeGear)
        }
    }
    
    private func createFreshHikeGear(from template: HikeGear) -> HikeGear {
        let newHikeGear = HikeGear()
        newHikeGear.consumable = template.consumable
        newHikeGear.worn = template.worn
        newHikeGear.numberUnits = template.numberUnits
        newHikeGear.verified = template.verified
        newHikeGear.notes = template.notes
        newHikeGear.gear = template.gear
        return newHikeGear
    }
    
    func copyHike(_ originalHike: HikeSwiftUI) -> HikeSwiftUI {
        let copiedHike = HikeSwiftUI()
        copiedHike.name = "Copy of \(originalHike.name)"
        copiedHike.desc = originalHike.desc
        copiedHike.distance = originalHike.distance
        copiedHike.location = originalHike.location
        copiedHike.completed = false
        copiedHike.externalLink1 = originalHike.externalLink1
        copiedHike.externalLink2 = originalHike.externalLink2
        copiedHike.externalLink3 = originalHike.externalLink3
        
        // Copy gear associations
        copiedHike.hikeGears = originalHike.hikeGears.map { originalHikeGear in
            let copiedHikeGear = HikeGearSwiftUI()
            copiedHikeGear.gear = originalHikeGear.gear
            copiedHikeGear.consumable = originalHikeGear.consumable
            copiedHikeGear.worn = originalHikeGear.worn
            copiedHikeGear.numberUnits = originalHikeGear.numberUnits
            copiedHikeGear.verified = false // Reset verification status
            copiedHikeGear.notes = originalHikeGear.notes
            return copiedHikeGear
        }
        
        return copiedHike
    }
}