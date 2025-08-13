//
//  HikeSwiftUI.swift
//  PackPlanner
//
//  Created by Claude on SwiftUI Migration
//

import Foundation
import SwiftUI
import RealmSwift
import Combine

class HikeSwiftUI: ObservableObject {
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
    private var weightCacheValid = false
    
    private var cancellables = Set<AnyCancellable>()
    
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
        if let cached = _totalWeight, weightCacheValid {
            return cached
        }
        let calculated = hikeGears.reduce(0) { total, hikeGear in
            total + (hikeGear.gear?.weightInGrams ?? 0) * Double(hikeGear.numberUnits)
        }
        _totalWeight = calculated
        return calculated
    }
    
    var baseWeight: Double {
        if let cached = _baseWeight, weightCacheValid {
            return cached
        }
        let calculated = hikeGears.filter { !$0.worn && !$0.consumable }.reduce(0) { total, hikeGear in
            total + (hikeGear.gear?.weightInGrams ?? 0) * Double(hikeGear.numberUnits)
        }
        _baseWeight = calculated
        return calculated
    }
    
    var wornWeight: Double {
        if let cached = _wornWeight, weightCacheValid {
            return cached
        }
        let calculated = hikeGears.filter { $0.worn }.reduce(0) { total, hikeGear in
            total + (hikeGear.gear?.weightInGrams ?? 0) * Double(hikeGear.numberUnits)
        }
        _wornWeight = calculated
        return calculated
    }
    
    var consumableWeight: Double {
        if let cached = _consumableWeight, weightCacheValid {
            return cached
        }
        let calculated = hikeGears.filter { $0.consumable }.reduce(0) { total, hikeGear in
            total + (hikeGear.gear?.weightInGrams ?? 0) * Double(hikeGear.numberUnits)
        }
        _consumableWeight = calculated
        return calculated
    }
    
    private func invalidateWeightCache() {
        _totalWeight = nil
        _baseWeight = nil
        _wornWeight = nil
        _consumableWeight = nil
        weightCacheValid = false
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

// Bridge functions for converting between legacy and modern models
extension HikeSwiftUI {
    convenience init(from hike: Hike) {
        self.init()
        self.name = hike.name
        self.desc = hike.desc
        self.distance = hike.distance
        self.location = hike.location
        self.completed = hike.completed
        self.externalLink1 = hike.externalLink1 ?? ""
        self.externalLink2 = hike.externalLink2 ?? ""
        self.externalLink3 = hike.externalLink3 ?? ""
        
        // Convert HikeGear relationships
        self.hikeGears = hike.hikeGears.compactMap { legacyHikeGear in
            if let gear = legacyHikeGear.gear {
                let hikeGearSwiftUI = HikeGearSwiftUI(from: legacyHikeGear)
                hikeGearSwiftUI.gear = GearSwiftUI(from: gear)
                return hikeGearSwiftUI
            }
            return nil
        }
    }
    
    func toLegacyHike() -> Hike {
        let hike = Hike()
        hike.name = self.name
        hike.desc = self.desc
        hike.distance = self.distance
        hike.location = self.location
        hike.completed = self.completed
        hike.externalLink1 = self.externalLink1.isEmpty ? nil : self.externalLink1
        hike.externalLink2 = self.externalLink2.isEmpty ? nil : self.externalLink2
        hike.externalLink3 = self.externalLink3.isEmpty ? nil : self.externalLink3
        return hike
    }
}