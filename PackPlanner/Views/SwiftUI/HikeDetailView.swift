//
//  HikeDetailView.swift
//  PackPlanner
//
//  Created by Claude on SwiftUI Migration
//

import SwiftUI

struct HikeDetailView: View {
    @State var hike: HikeSwiftUI
    @State private var dataService = DataService.shared
    @State private var settingsManager = SettingsManagerSwiftUI.shared
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
                    ContentUnavailableView(
                        showPendingOnly ? "No Pending Items" : "No Gear Added",
                        systemImage: "backpack",
                        description: Text(showPendingOnly ? "All items have been verified." : "Add gear to start planning this hike.")
                    )
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
            }
        }
    }
    
    private func removeGear(_ hikeGear: HikeGearSwiftUI) {
        if let index = hike.hikeGears.firstIndex(where: { $0.id == hikeGear.id }) {
            hike.hikeGears.remove(at: index)
            dataService.updateHike(hike)
        }
    }
}

struct HikeHeaderView: View {
    let hike: HikeSwiftUI
    @State private var settingsManager = SettingsManagerSwiftUI.shared
    
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
    @State private var settingsManager = SettingsManagerSwiftUI.shared
    
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
    @State var hikeGear: HikeGearSwiftUI
    let hike: HikeSwiftUI
    @State private var dataService = DataService.shared
    @State private var settingsManager = SettingsManagerSwiftUI.shared
    
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
                HStack {
                    Button(action: {
                        hikeGear.worn.toggle()
                        dataService.updateHike(hike)
                    }) {
                        Image(systemName: hikeGear.worn ? "tshirt.fill" : "tshirt")
                            .foregroundColor(hikeGear.worn ? .green : .gray)
                    }
                    
                    Button(action: {
                        hikeGear.consumable.toggle()
                        dataService.updateHike(hike)
                    }) {
                        Image(systemName: hikeGear.consumable ? "leaf.fill" : "leaf")
                            .foregroundColor(hikeGear.consumable ? .orange : .gray)
                    }
                    
                    Button(action: {
                        hikeGear.verified.toggle()
                        dataService.updateHike(hike)
                    }) {
                        Image(systemName: hikeGear.verified ? "checkmark.circle.fill" : "checkmark.circle")
                            .foregroundColor(hikeGear.verified ? .blue : .gray)
                    }
                }
            }
        }
        .padding(.vertical, 2)
    }
}

struct AddGearToHikeView: View {
    @State var hike: HikeSwiftUI
    @State private var dataService = DataService.shared
    @State private var searchText = ""
    @State private var selectedGear: Set<String> = []
    
    @Environment(\.dismiss) private var dismiss
    
    private var availableGear: [GearSwiftUI] {
        let existingGearIds = Set(hike.hikeGears.compactMap { $0.gear?.id })
        return dataService.searchGear(query: searchText).filter { gear in
            !existingGearIds.contains(gear.id)
        }
    }
    
    var body: some View {
        NavigationView {
            VStack {
                SearchBar(text: $searchText)
                
                List(availableGear, id: \.id) { gear in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(gear.name)
                                .font(.headline)
                            Text(gear.category)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        if selectedGear.contains(gear.id) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.blue)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        if selectedGear.contains(gear.id) {
                            selectedGear.remove(gear.id)
                        } else {
                            selectedGear.insert(gear.id)
                        }
                    }
                }
            }
            .navigationTitle("Add Gear")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        addSelectedGear()
                        dismiss()
                    }
                    .disabled(selectedGear.isEmpty)
                }
            }
        }
    }
    
    private func addSelectedGear() {
        for gearId in selectedGear {
            if let gear = dataService.gears.first(where: { $0.id == gearId }) {
                hike.addGear(gear)
            }
        }
        dataService.updateHike(hike)
    }
}

#Preview {
    HikeDetailView(hike: HikeSwiftUI(name: "Sample Hike", desc: "A beautiful mountain trail"))
}