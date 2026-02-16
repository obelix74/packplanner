//
//  DataService.swift
//  PackPlanner
//
//  Created by Claude on SwiftUI Migration
//

import Foundation
import SwiftUI
import CoreData
import Combine
import os

class DataService: ObservableObject {
    static let shared = DataService()

    private let context = CoreDataStack.shared.viewContext

    @Published var gears: [GearSwiftUI] = []
    @Published var hikes: [HikeSwiftUI] = []

    private init() {
        loadData()
    }

    // MARK: - Data Loading

    func loadData() {
        loadGears()
        loadHikes()
    }

    func loadGears() {
        let fetchRequest: NSFetchRequest<GearEntity> = GearEntity.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]

        do {
            let results = try context.fetch(fetchRequest)
            self.gears = results.map { GearSwiftUI(fromCoreData: $0) }
        } catch {
            Logger.coreData.error("Error loading gears: \(error)")
            self.gears = []
        }
    }

    func loadHikes() {
        let fetchRequest: NSFetchRequest<HikeEntity> = HikeEntity.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]

        do {
            let results = try context.fetch(fetchRequest)
            self.hikes = results.map { HikeSwiftUI(fromCoreData: $0) }
        } catch {
            Logger.coreData.error("Error loading hikes: \(error)")
            self.hikes = []
        }
    }

    // MARK: - Gear CRUD Operations

    func createGear(name: String, desc: String, weightInGrams: Double, category: String) -> GearSwiftUI? {
        let gearEntity = GearEntity(context: context)
        gearEntity.uuid = UUID().uuidString
        gearEntity.name = name
        gearEntity.desc = desc
        gearEntity.weightInGrams = weightInGrams
        gearEntity.category = category

        do {
            try context.save()
            let newGear = GearSwiftUI(fromCoreData: gearEntity)
            loadGears()
            return newGear
        } catch {
            Logger.coreData.error("Error creating gear '\(name)': \(error)")
            return nil
        }
    }

    func updateGear(_ gear: GearSwiftUI) {
        let fetchRequest: NSFetchRequest<GearEntity> = GearEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "uuid == %@", gear.id)

        do {
            let results = try context.fetch(fetchRequest)
            if let gearEntity = results.first {
                gearEntity.name = gear.name
                gearEntity.desc = gear.desc
                gearEntity.weightInGrams = gear.weightInGrams
                gearEntity.category = gear.category

                try context.save()
                loadGears()
            }
        } catch {
            Logger.coreData.error("Error updating gear: \(error)")
        }
    }

    func deleteGear(_ gear: GearSwiftUI) {
        let fetchRequest: NSFetchRequest<GearEntity> = GearEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "uuid == %@", gear.id)

        do {
            let results = try context.fetch(fetchRequest)
            if let gearEntity = results.first {
                context.delete(gearEntity)
                try context.save()
                loadGears()
            }
        } catch {
            Logger.coreData.error("Error deleting gear: \(error)")
        }
    }

    // MARK: - Hike CRUD Operations

    func createHike(name: String, desc: String = "", distance: String = "", location: String = "") -> HikeSwiftUI? {
        let hikeEntity = HikeEntity(context: context)
        hikeEntity.uuid = UUID().uuidString
        hikeEntity.name = name
        hikeEntity.desc = desc
        hikeEntity.distance = distance
        hikeEntity.location = location
        hikeEntity.completed = false

        do {
            try context.save()
            let newHike = HikeSwiftUI(fromCoreData: hikeEntity)
            loadHikes()
            return newHike
        } catch {
            Logger.coreData.error("Error creating hike '\(name)': \(error)")
            return nil
        }
    }

    func updateHike(_ hike: HikeSwiftUI) {
        let fetchRequest: NSFetchRequest<HikeEntity> = HikeEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "uuid == %@", hike.id)

        do {
            let results = try context.fetch(fetchRequest)
            if let hikeEntity = results.first {
                // Update basic properties
                hikeEntity.name = hike.name
                hikeEntity.desc = hike.desc
                hikeEntity.distance = hike.distance
                hikeEntity.location = hike.location
                hikeEntity.completed = hike.completed
                hikeEntity.externalLink1 = hike.externalLink1
                hikeEntity.externalLink2 = hike.externalLink2
                hikeEntity.externalLink3 = hike.externalLink3

                // Update hikeGears relationships
                let existingHikeGears = (hikeEntity.hikeGears as? Set<HikeGearEntity>) ?? []

                // Delete all existing HikeGear relationships
                for hikeGear in existingHikeGears {
                    context.delete(hikeGear)
                }

                // Create new HikeGear relationships from hike.hikeGears
                for hikeGearSwiftUI in hike.hikeGears {
                    if let gearId = hikeGearSwiftUI.gear?.id {
                        // Find the gear in Core Data
                        let gearFetchRequest: NSFetchRequest<GearEntity> = GearEntity.fetchRequest()
                        gearFetchRequest.predicate = NSPredicate(format: "uuid == %@", gearId)

                        if let gearEntity = try context.fetch(gearFetchRequest).first {
                            let hikeGearEntity = HikeGearEntity(context: context)
                            hikeGearEntity.numberUnits = Int32(hikeGearSwiftUI.numberUnits)
                            hikeGearEntity.consumable = hikeGearSwiftUI.consumable
                            hikeGearEntity.worn = hikeGearSwiftUI.worn
                            hikeGearEntity.verified = hikeGearSwiftUI.verified
                            hikeGearEntity.notes = hikeGearSwiftUI.notes
                            hikeGearEntity.gear = gearEntity
                            hikeGearEntity.hike = hikeEntity
                        }
                    }
                }

                try context.save()
                loadHikes()
            }
        } catch {
            Logger.coreData.error("Error updating hike: \(error)")
        }
    }

    func deleteHike(_ hike: HikeSwiftUI) {
        let fetchRequest: NSFetchRequest<HikeEntity> = HikeEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "uuid == %@", hike.id)

        do {
            let results = try context.fetch(fetchRequest)
            if let hikeEntity = results.first {
                context.delete(hikeEntity)
                try context.save()
                loadHikes()
            }
        } catch {
            Logger.coreData.error("Error deleting hike: \(error)")
        }
    }

    // MARK: - HikeGear Operations

    func addGearToHike(_ gear: GearSwiftUI, hike: HikeSwiftUI, quantity: Int = 1) {
        let hikeFetchRequest: NSFetchRequest<HikeEntity> = HikeEntity.fetchRequest()
        hikeFetchRequest.predicate = NSPredicate(format: "uuid == %@", hike.id)

        let gearFetchRequest: NSFetchRequest<GearEntity> = GearEntity.fetchRequest()
        gearFetchRequest.predicate = NSPredicate(format: "uuid == %@", gear.id)

        do {
            let hikeResults = try context.fetch(hikeFetchRequest)
            let gearResults = try context.fetch(gearFetchRequest)

            if let hikeEntity = hikeResults.first, let gearEntity = gearResults.first {
                let hikeGearEntity = HikeGearEntity(context: context)
                hikeGearEntity.hike = hikeEntity
                hikeGearEntity.gear = gearEntity
                hikeGearEntity.numberUnits = Int32(quantity)
                hikeGearEntity.worn = false
                hikeGearEntity.consumable = false
                hikeGearEntity.verified = false

                try context.save()
                loadHikes()
            }
        } catch {
            Logger.coreData.error("Error adding gear to hike: \(error)")
        }
    }

    func removeGearFromHike(_ gear: GearSwiftUI, hike: HikeSwiftUI) {
        let fetchRequest: NSFetchRequest<HikeGearEntity> = HikeGearEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "hike.uuid == %@ AND gear.uuid == %@", hike.id, gear.id)

        do {
            let results = try context.fetch(fetchRequest)
            for hikeGearEntity in results {
                context.delete(hikeGearEntity)
            }
            try context.save()
            loadHikes()
        } catch {
            Logger.coreData.error("Error removing gear from hike: \(error)")
        }
    }
}
