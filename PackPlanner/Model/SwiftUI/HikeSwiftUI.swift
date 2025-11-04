//
//  HikeSwiftUI.swift
//  PackPlanner
//
//  Created by Claude on SwiftUI Migration
//

import Foundation
import SwiftUI
import CoreData
import Combine

class HikeSwiftUI: ObservableObject, Identifiable {
    @Published var id: String = UUID().uuidString
    @Published var name: String = ""
    @Published var desc: String = ""
    @Published var distance: String = ""
    @Published var location: String = ""
    @Published var completed: Bool = false
    @Published var externalLink1: String = ""
    @Published var externalLink2: String = ""
    @Published var externalLink3: String = ""
    @Published var hikeGears: [HikeGearSwiftUI] = [] {
        didSet {
            setupChildObservation()
            invalidateWeightCache()
        }
    }
    
    // Weight caching properties
    private var _totalWeight: Double?
    private var _baseWeight: Double?
    private var _wornWeight: Double?
    private var _consumableWeight: Double?

    // Thread-safe queue for weight cache operations
    private let cacheQueue = DispatchQueue(label: "com.packplanner.hike.weightcache", attributes: .concurrent)
    
    private var cancellables = Set<AnyCancellable>()
    
    deinit {
        cancellables.removeAll()
    }
    
    init() {
        setupChildObservation()
    }
    
    init(name: String, desc: String = "", distance: String = "", location: String = "") {
        self.name = name
        self.desc = desc
        self.distance = distance
        self.location = location
        setupChildObservation()
    }
    
    var totalWeight: Double {
        return cacheQueue.sync {
            if let cached = _totalWeight {
                return cached
            }
            let calculated = hikeGears.reduce(0) { total, hikeGear in
                total + (hikeGear.gear?.weightInGrams ?? 0) * Double(hikeGear.numberUnits)
            }
            _totalWeight = calculated
            return calculated
        }
    }

    var baseWeight: Double {
        return cacheQueue.sync {
            if let cached = _baseWeight {
                return cached
            }
            let calculated = hikeGears.filter { !$0.worn && !$0.consumable }.reduce(0) { total, hikeGear in
                total + (hikeGear.gear?.weightInGrams ?? 0) * Double(hikeGear.numberUnits)
            }
            _baseWeight = calculated
            return calculated
        }
    }

    var wornWeight: Double {
        return cacheQueue.sync {
            if let cached = _wornWeight {
                return cached
            }
            let calculated = hikeGears.filter { $0.worn }.reduce(0) { total, hikeGear in
                total + (hikeGear.gear?.weightInGrams ?? 0) * Double(hikeGear.numberUnits)
            }
            _wornWeight = calculated
            return calculated
        }
    }

    var consumableWeight: Double {
        return cacheQueue.sync {
            if let cached = _consumableWeight {
                return cached
            }
            let calculated = hikeGears.filter { $0.consumable }.reduce(0) { total, hikeGear in
                total + (hikeGear.gear?.weightInGrams ?? 0) * Double(hikeGear.numberUnits)
            }
            _consumableWeight = calculated
            return calculated
        }
    }
    
    func invalidateWeightCache() {
        cacheQueue.sync(flags: .barrier) {
            self._totalWeight = nil
            self._baseWeight = nil
            self._wornWeight = nil
            self._consumableWeight = nil
        }
    }
    
    private func setupChildObservation() {
        // Clear existing subscriptions
        cancellables.removeAll()
        
        // Subscribe to changes in each child HikeGearSwiftUI object
        for hikeGear in hikeGears {
            hikeGear.objectWillChange
                .sink { [weak self] _ in
                    self?.invalidateWeightCache()
                    self?.objectWillChange.send()
                }
                .store(in: &cancellables)
        }
    }
    
    func addGear(_ gear: GearSwiftUI, quantity: Int = 1) {
        // Check if this gear is already in the hike to prevent duplicates
        if !hikeGears.contains(where: { $0.gear?.id == gear.id }) {
            let hikeGear = HikeGearSwiftUI()
            hikeGear.gear = gear
            hikeGear.numberUnits = quantity
            hikeGears.append(hikeGear)
        }
    }
    
    
    func removeGear(at index: Int) {
        guard index < hikeGears.count else { return }
        hikeGears.remove(at: index)
    }
}

// Bridge functions for Core Data
extension HikeSwiftUI {
    convenience init(fromCoreData hike: HikeEntity) {
        self.init()
        self.name = hike.name
        self.desc = hike.desc
        self.distance = hike.distance
        self.location = hike.location
        self.completed = hike.completed
        self.externalLink1 = hike.externalLink1 ?? ""
        self.externalLink2 = hike.externalLink2 ?? ""
        self.externalLink3 = hike.externalLink3 ?? ""

        // Convert HikeGear relationships from Core Data
        if let hikeGearsSet = hike.hikeGears as? Set<HikeGearEntity> {
            self.hikeGears = hikeGearsSet.compactMap { hikeGearEntity in
                if let gear = hikeGearEntity.gear {
                    let hikeGearSwiftUI = HikeGearSwiftUI()
                    hikeGearSwiftUI.numberUnits = Int(hikeGearEntity.numberUnits)
                    hikeGearSwiftUI.worn = hikeGearEntity.worn
                    hikeGearSwiftUI.consumable = hikeGearEntity.consumable
                    hikeGearSwiftUI.verified = hikeGearEntity.verified
                    hikeGearSwiftUI.notes = hikeGearEntity.notes ?? ""
                    hikeGearSwiftUI.gear = GearSwiftUI(fromCoreData: gear)
                    return hikeGearSwiftUI
                }
                return nil
            }
        }
    }
}