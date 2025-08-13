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

class DataService: ObservableObject {
    static let shared = DataService()
    
    private let realm: Realm
    @Published private var gearCache: [GearSwiftUI] = []
    @Published private var hikeCache: [HikeSwiftUI] = []
    
    private init() {
        do {
            self.realm = try Realm()
            // Clean up any database duplicates on startup
            cleanupDatabaseDuplicates()
            // Also clean up gear duplicates
            GearBrain.cleanupDuplicateGears()
        } catch {
            fatalError("Failed to initialize Realm: \(error)")
        }
    }
    
    // MARK: - Data Loading
    
    func loadData() {
        loadGear()
        loadHikes()
    }
    
    private func loadGear() {
        let gearObjects = realm.objects(Gear.self)
        gearCache = gearObjects.map { GearSwiftUI(from: $0) }
    }
    
    private func loadHikes() {
        let hikeObjects = realm.objects(Hike.self)
        hikeCache = hikeObjects.map { hikeObj in
            return HikeSwiftUI(from: hikeObj)
        }
    }
    
    // MARK: - Gear CRUD Operations
    
    var gears: [GearSwiftUI] {
        return gearCache
    }
    
    func addGear(_ gear: GearSwiftUI) {
        do {
            try realm.write {
                let legacyGear = gear.toLegacyGear()
                realm.add(legacyGear)
                gearCache.append(gear)
            }
        } catch {
            print("Error adding gear: \(error)")
        }
    }
    
    func updateGear(_ gear: GearSwiftUI) {
        do {
            try realm.write {
                if let existingGear = realm.objects(Gear.self).filter("uuid == %@", gear.id).first {
                    existingGear.name = gear.name
                    existingGear.desc = gear.desc
                    existingGear.weightInGrams = gear.weightInGrams
                    existingGear.category = gear.category
                }
                
                if let index = gearCache.firstIndex(where: { $0.id == gear.id }) {
                    gearCache[index] = gear
                }
            }
        } catch {
            print("Error updating gear: \(error)")
        }
    }
    
    func deleteGear(_ gear: GearSwiftUI) {
        do {
            try realm.write {
                if let gearToDelete = realm.objects(Gear.self).filter("uuid == %@", gear.id).first {
                    realm.delete(gearToDelete)
                }
                gearCache.removeAll { $0.id == gear.id }
            }
        } catch {
            print("Error deleting gear: \(error)")
        }
    }
    
    // MARK: - Hike CRUD Operations
    
    var hikes: [HikeSwiftUI] {
        return hikeCache
    }
    
    func addHike(_ hike: HikeSwiftUI) {
        do {
            try realm.write {
                let legacyHike = hike.toLegacyHike()
                
                // Add HikeGear relationships
                for hikeGearSwiftUI in hike.hikeGears {
                    let legacyHikeGear = hikeGearSwiftUI.toLegacyHikeGear()
                    realm.add(legacyHikeGear)
                    legacyHike.hikeGears.append(legacyHikeGear)
                }
                
                realm.add(legacyHike)
                hikeCache.append(hike)
            }
        } catch {
            print("Error adding hike: \(error)")
        }
    }
    
    func updateHike(_ hike: HikeSwiftUI, originalName: String? = nil) {
        do {
            try realm.write {
                // Find existing hike using original name if provided, otherwise current name
                let nameToSearch = originalName ?? hike.name
                if let existingHike = realm.objects(Hike.self).filter("name == %@", nameToSearch).first {
                    existingHike.name = hike.name
                    existingHike.desc = hike.desc
                    existingHike.distance = hike.distance
                    existingHike.location = hike.location
                    existingHike.completed = hike.completed
                    existingHike.externalLink1 = hike.externalLink1.isEmpty ? nil : hike.externalLink1
                    existingHike.externalLink2 = hike.externalLink2.isEmpty ? nil : hike.externalLink2
                    existingHike.externalLink3 = hike.externalLink3.isEmpty ? nil : hike.externalLink3
                    
                    // Update HikeGear relationships more carefully
                    // First, remove existing HikeGear entries
                    realm.delete(existingHike.hikeGears)
                    existingHike.hikeGears.removeAll()
                    
                    // Group by gear ID to prevent duplicates
                    let uniqueHikeGears = Dictionary(grouping: hike.hikeGears) { $0.gear?.id ?? "" }
                        .compactMapValues { $0.first } // Take only first occurrence of each gear ID
                        .values
                    
                    // Add current HikeGear relationships
                    for hikeGearSwiftUI in uniqueHikeGears {
                        let legacyHikeGear = hikeGearSwiftUI.toLegacyHikeGear()
                        realm.add(legacyHikeGear)
                        existingHike.hikeGears.append(legacyHikeGear)
                    }
                }
                
                if let index = hikeCache.firstIndex(where: { $0.id == hike.id }) {
                    hikeCache[index] = hike
                }
            }
        } catch {
            print("Error updating hike: \(error)")
        }
    }
    
    func deleteHike(_ hike: HikeSwiftUI) {
        do {
            try realm.write {
                if let hikeToDelete = realm.objects(Hike.self).filter("name == %@", hike.name).first {
                    realm.delete(hikeToDelete.hikeGears)
                    realm.delete(hikeToDelete)
                }
                hikeCache.removeAll { $0.id == hike.id }
            }
        } catch {
            print("Error deleting hike: \(error)")
        }
    }
    
    // MARK: - Search and Filter
    
    func searchGear(query: String) -> [GearSwiftUI] {
        if query.isEmpty {
            return gearCache
        }
        return gearCache.filter { gear in
            gear.name.localizedCaseInsensitiveContains(query) ||
            gear.desc.localizedCaseInsensitiveContains(query) ||
            gear.category.localizedCaseInsensitiveContains(query)
        }
    }
    
    func searchHikes(query: String) -> [HikeSwiftUI] {
        if query.isEmpty {
            return hikeCache
        }
        return hikeCache.filter { hike in
            hike.name.localizedCaseInsensitiveContains(query) ||
            hike.desc.localizedCaseInsensitiveContains(query) ||
            hike.location.localizedCaseInsensitiveContains(query)
        }
    }
    
    func gearByCategory() -> [String: [GearSwiftUI]] {
        return Dictionary(grouping: gearCache) { $0.category }
    }
    
    // MARK: - Utility Methods
    
    func cleanupDatabaseDuplicates() {
        do {
            try realm.write {
                let allHikes = realm.objects(Hike.self)
                for hike in allHikes {
                    let hikeGearsArray = Array(hike.hikeGears)
                    var seenGearUUIDs = Set<String>()
                    var duplicatesToRemove: [HikeGear] = []
                    
                    for hikeGear in hikeGearsArray {
                        if let gear = hikeGear.gearList.first {
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
                        realm.delete(duplicate)
                    }
                }
            }
            
            // Reload data after cleanup
            loadData()
            
        } catch {
            print("Error cleaning up database duplicates: \(error)")
        }
    }
    
    func cleanupDuplicateHikeGears() {
        do {
            try realm.write {
                let allHikes = realm.objects(Hike.self)
                for hike in allHikes {
                    // Create a dictionary to store unique gear entries
                    var uniqueGearEntries: [String: HikeGear] = [:]
                    
                    // Process each hikeGear and keep only the first occurrence of each gear
                    for hikeGear in hike.hikeGears {
                        if let gear = hikeGear.gearList.first {
                            let gearId = gear.uuid
                            
                            // If we haven't seen this gear ID before, keep this hikeGear
                            if uniqueGearEntries[gearId] == nil {
                                uniqueGearEntries[gearId] = hikeGear
                            }
                        }
                    }
                    
                    // Remove ALL existing hikeGears from this hike
                    let allHikeGears = Array(hike.hikeGears)
                    hike.hikeGears.removeAll()
                    
                    // Delete the old hikeGear objects from Realm
                    realm.delete(allHikeGears)
                    
                    // Re-add only the unique entries
                    for (_, uniqueHikeGear) in uniqueGearEntries {
                        // Create a fresh HikeGear object to avoid Realm reference issues
                        let newHikeGear = HikeGear()
                        newHikeGear.consumable = uniqueHikeGear.consumable
                        newHikeGear.worn = uniqueHikeGear.worn
                        newHikeGear.numberUnits = uniqueHikeGear.numberUnits
                        newHikeGear.verified = uniqueHikeGear.verified
                        newHikeGear.notes = uniqueHikeGear.notes
                        
                        // Add the gear reference
                        if let gear = uniqueHikeGear.gearList.first {
                            newHikeGear.gearList.append(gear)
                        }
                        
                        // Add to Realm and to the hike
                        realm.add(newHikeGear)
                        hike.hikeGears.append(newHikeGear)
                    }
                }
            }
            
            // Reload data after cleanup
            loadData()
            
        } catch {
            print("Database cleanup failed: \(error)")
        }
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