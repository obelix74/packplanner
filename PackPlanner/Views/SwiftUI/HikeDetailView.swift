//
//  HikeDetailView.swift
//  PackPlanner
//
//  Created by Claude on SwiftUI Migration
//

import SwiftUI
import CoreData

struct HikeDetailView: View {
    @ObservedObject var hike: HikeSwiftUI
    @StateObject private var dataService = DataService.shared
    @StateObject private var settingsManager = SettingsManagerSwiftUI.shared
    @State private var showingAddGear = false
    @State private var showPendingOnly = false

    @Environment(\.dismiss) private var dismiss
    
    private var filteredGears: [HikeGearSwiftUI] {
        if showPendingOnly {
            return hike.hikeGears.filter { !$0.verified }
        } else {
            return hike.hikeGears
        }
    }
    
    private var gearByCategory: [String: [HikeGearSwiftUI]] {
        Dictionary(grouping: filteredGears) { hikeGear in
            hikeGear.gear?.category ?? "Unknown"
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header with hike info and weights
                HikeHeaderView(hike: hike)

                // Pending/All toggle
                Picker("View", selection: $showPendingOnly) {
                    Text("All Items").tag(false)
                    Text("Pending Only").tag(true)
                }
                .pickerStyle(.segmented)
                .padding()
                
                // Gear list
                if filteredGears.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "backpack")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)

                        Text(showPendingOnly ? "No Pending Items" : "No Gear Added")
                            .font(.title2)
                            .foregroundColor(.primary)

                        Text(showPendingOnly ? "All items have been verified." : "Add gear to start planning this hike.")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding()
                } else {
                    List {
                        ForEach(gearByCategory.keys.sorted(), id: \.self) { category in
                            Section(category) {
                                ForEach(gearByCategory[category] ?? [], id: \.id) { hikeGear in
                                    HikeGearRowView(hikeGear: hikeGear, hike: hike)
                                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                            Button("Remove", role: .destructive) {
                                                removeGear(hikeGear)
                                            }
                                        }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle(hike.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add Gear") {
                        showingAddGear = true
                    }
                }
            }
            .sheet(isPresented: $showingAddGear) {
                AddGearToHikeView(hike: hike)
                    .onDisappear {
                        reloadHikeData()
                    }
            }
        }
    }
    
    private func removeGear(_ hikeGear: HikeGearSwiftUI) {
        if let index = hike.hikeGears.firstIndex(where: { $0.id == hikeGear.id }) {
            hike.hikeGears.remove(at: index)
            dataService.updateHike(hike)
        }
    }

    private func reloadHikeData() {
        // Fetch the hike from Core Data to get updated gear list
        let context = CoreDataStack.shared.viewContext
        let fetchRequest: NSFetchRequest<HikeEntity> = HikeEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "name == %@", hike.name)

        do {
            if let hikeEntity = try context.fetch(fetchRequest).first {
                // Reload hikeGears from Core Data
                let hikeGearEntities = (hikeEntity.hikeGears as? Set<HikeGearEntity>) ?? []

                hike.hikeGears = hikeGearEntities.map { hikeGearEntity in
                    let hikeGear = HikeGearSwiftUI()
                    hikeGear.id = UUID().uuidString
                    hikeGear.numberUnits = Int(hikeGearEntity.numberUnits)
                    hikeGear.consumable = hikeGearEntity.consumable
                    hikeGear.worn = hikeGearEntity.worn
                    hikeGear.verified = hikeGearEntity.verified
                    hikeGear.notes = hikeGearEntity.notes ?? ""

                    // Load the associated gear
                    if let gearEntity = hikeGearEntity.gear {
                        hikeGear.gear = GearSwiftUI(fromCoreData: gearEntity)
                    }

                    return hikeGear
                }

                // Force UI update
                hike.objectWillChange.send()
            }
        } catch {
            // Silently handle error
        }
    }
}

struct HikeHeaderView: View {
    @ObservedObject var hike: HikeSwiftUI
    @StateObject private var settingsManager = SettingsManagerSwiftUI.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if !hike.desc.isEmpty {
                Text(hike.desc)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            HStack {
                if !hike.location.isEmpty {
                    Label(hike.location, systemImage: "location")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                if !hike.distance.isEmpty {
                    Label(hike.distance, systemImage: "ruler")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            // Weight summary
            VStack(spacing: 8) {
                HStack {
                    WeightSummaryItem(
                        title: "Total Weight",
                        weight: hike.totalWeight,
                        color: .primary
                    )
                    
                    Spacer()
                    
                    WeightSummaryItem(
                        title: "Base Weight",
                        weight: hike.baseWeight,
                        color: .blue
                    )
                }
                
                HStack {
                    WeightSummaryItem(
                        title: "Worn Weight",
                        weight: hike.wornWeight,
                        color: .green
                    )
                    
                    Spacer()
                    
                    WeightSummaryItem(
                        title: "Consumable",
                        weight: hike.consumableWeight,
                        color: .orange
                    )
                }
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)
        }
        .padding()
    }
}

struct WeightSummaryItem: View {
    let title: String
    let weight: Double
    let color: Color
    @StateObject private var settingsManager = SettingsManagerSwiftUI.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(settingsManager.formatWeight(weight))
                .font(.headline)
                .foregroundColor(color)
        }
    }
}

struct HikeGearRowView: View {
    @ObservedObject var hikeGear: HikeGearSwiftUI
    let hike: HikeSwiftUI
    @StateObject private var dataService = DataService.shared
    @StateObject private var settingsManager = SettingsManagerSwiftUI.shared

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(hikeGear.gear?.name ?? "Unknown Gear")
                    .font(.headline)

                if let desc = hikeGear.gear?.desc, !desc.isEmpty {
                    Text(desc)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }

                HStack {
                    Text("Qty: \(hikeGear.numberUnits)")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text(hikeGear.weightString(imperial: settingsManager.isImperial))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            VStack {
                HStack(spacing: 16) {
                    Button(action: {
                        hikeGear.worn.toggle()
                        hike.invalidateWeightCache()
                        hike.objectWillChange.send()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                            dataService.updateHike(hike)
                        }
                    }) {
                        Image(systemName: hikeGear.worn ? "tshirt.fill" : "tshirt")
                            .foregroundColor(hikeGear.worn ? .green : .gray)
                            .font(.title3)
                    }
                    .buttonStyle(.borderless)

                    Button(action: {
                        hikeGear.consumable.toggle()
                        hike.invalidateWeightCache()
                        hike.objectWillChange.send()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                            dataService.updateHike(hike)
                        }
                    }) {
                        Image(systemName: hikeGear.consumable ? "leaf.fill" : "leaf")
                            .foregroundColor(hikeGear.consumable ? .orange : .gray)
                            .font(.title3)
                    }
                    .buttonStyle(.borderless)

                    Button(action: {
                        hikeGear.verified.toggle()
                        hike.invalidateWeightCache()
                        hike.objectWillChange.send()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                            dataService.updateHike(hike)
                        }
                    }) {
                        Image(systemName: hikeGear.verified ? "checkmark.circle.fill" : "checkmark.circle")
                            .foregroundColor(hikeGear.verified ? .blue : .gray)
                            .font(.title3)
                    }
                    .buttonStyle(.borderless)
                }
            }
        }
        .padding(.vertical, 2)
    }
}


#Preview {
    HikeDetailView(hike: HikeSwiftUI(name: "Sample Hike", desc: "A beautiful mountain trail"))
}