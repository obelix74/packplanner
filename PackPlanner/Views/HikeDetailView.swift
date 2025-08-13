//
//  HikeDetailView.swift
//  PackPlanner
//
//  Created by Claude on SwiftUI Migration
//

import SwiftUI

struct HikeDetailView: View {
    @ObservedObject var hike: HikeSwiftUI
    @State private var dataService = DataService.shared
    @State private var settingsManager = SettingsManagerSwiftUI.shared
    @State private var showingAddGear = false
    @State private var showingEditHike = false
    @State private var showPendingOnly = false
    @State private var saveTimer: Timer?
    
    @Environment(\.dismiss) private var dismiss
    
    private var filteredGears: [HikeGearSwiftUI] {
        let baseGears = showPendingOnly ? hike.hikeGears.filter { !$0.verified } : hike.hikeGears
        
        // Remove duplicates by gear ID - only keep the first occurrence of each gear
        var seenGearIds = Set<String>()
        let uniqueGears = baseGears.filter { hikeGear in
            guard let gearId = hikeGear.gear?.id else { return false }
            
            if seenGearIds.contains(gearId) {
                return false // This is a duplicate, filter it out
            } else {
                seenGearIds.insert(gearId)
                return true // First occurrence, keep it
            }
        }
        
        return uniqueGears
    }
    
    private var gearByCategory: [String: [HikeGearSwiftUI]] {
        Dictionary(grouping: filteredGears) { hikeGear in
            hikeGear.gear?.category ?? "Unknown"
        }
    }
    
    private var allItemsOption: some View {
        Text("All Items").tag(false)
    }
    
    private var pendingOnlyOption: some View {
        Text("Pending Only").tag(true)
    }
    
    private var pickerContent: some View {
        Picker("View", selection: $showPendingOnly) {
            allItemsOption
            pendingOnlyOption
        }
    }
    
    private var togglePicker: some View {
        pickerContent
            .pickerStyle(.segmented)
            .padding()
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "backpack")
                .font(.system(size: 64))
                .foregroundColor(.gray)
            
            Text(showPendingOnly ? "No Pending Items" : "No Gear Added")
                .font(.title2)
                .fontWeight(.medium)
            
            Text(showPendingOnly ? "All items have been verified." : "Add gear to start planning this hike.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var gearSections: some View {
        ForEach(sortedCategories, id: \.self) { category in
            let categoryGears = gearByCategory[category] ?? []
            Section(category) {
                ForEach(0..<categoryGears.count, id: \.self) { index in
                    gearRow(categoryGears[index])
                }
            }
        }
    }
    
    private var sortedCategories: [String] {
        gearByCategory.keys.sorted()
    }
    
    private func gearRow(_ hikeGear: HikeGearSwiftUI) -> some View {
        HikeGearRowView(hikeGear: hikeGear, hike: hike)
            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                Button("Remove", role: .destructive) {
                    removeGear(hikeGear)
                }
            }
    }
    
    private var gearListView: some View {
        List {
            gearSections
        }
    }
    
    private var contentView: some View {
        VStack(spacing: 0) {
            HikeHeaderView(hike: hike)
            togglePicker
            
            if filteredGears.isEmpty {
                emptyStateView
            } else {
                gearListView
            }
        }
    }
    
    var body: some View {
        NavigationView {
            contentView
                .navigationTitle(hike.name)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar(content: {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Done") {
                            dismiss()
                        }
                    }
                    
                    ToolbarItem(placement: .navigationBarTrailing) {
                        HStack {
                            Button("Edit") {
                                showingEditHike = true
                            }
                            
                            Button("Add Gear") {
                                showingAddGear = true
                            }
                        }
                    }
                })
                .sheet(isPresented: $showingAddGear) {
                    AddGearToHikeView(hike: hike)
                }
                .sheet(isPresented: $showingEditHike) {
                    NavigationView {
                        AddHikeView(hike: hike)
                    }
                    .navigationViewStyle(StackNavigationViewStyle())
                }
        }
        .onAppear {
            startAutoSave()
        }
        .onDisappear {
            stopAutoSave()
            dataService.updateHike(hike) // Final save on exit
        }
    }
    
    private func removeGear(_ hikeGear: HikeGearSwiftUI) {
        if let index = hike.hikeGears.firstIndex(where: { $0.id == hikeGear.id }) {
            hike.hikeGears.remove(at: index)
            dataService.updateHike(hike)
        }
    }
    
    private func startAutoSave() {
        // Re-enable auto-save with longer interval to prevent duplicates
        saveTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { _ in
            dataService.updateHike(hike)
        }
    }
    
    private func stopAutoSave() {
        saveTimer?.invalidate()
        saveTimer = nil
    }
}

struct HikeHeaderView: View {
    @ObservedObject var hike: HikeSwiftUI
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
    @ObservedObject var hikeGear: HikeGearSwiftUI
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
            
            HStack(spacing: 16) {
                Button(action: {
                    hikeGear.worn.toggle()
                    hike.objectWillChange.send() // Notify parent of change
                }) {
                    Image(systemName: hikeGear.worn ? "tshirt.fill" : "tshirt")
                        .foregroundColor(hikeGear.worn ? .green : .gray)
                        .font(.title3)
                }
                .buttonStyle(PlainButtonStyle())
                
                Button(action: {
                    hikeGear.consumable.toggle()
                    hike.objectWillChange.send() // Notify parent of change
                }) {
                    Image(systemName: hikeGear.consumable ? "leaf.fill" : "leaf")
                        .foregroundColor(hikeGear.consumable ? .orange : .gray)
                        .font(.title3)
                }
                .buttonStyle(PlainButtonStyle())
                
                Button(action: {
                    hikeGear.verified.toggle()
                    hike.objectWillChange.send() // Notify parent of change
                }) {
                    Image(systemName: hikeGear.verified ? "checkmark.circle.fill" : "checkmark.circle")
                        .foregroundColor(hikeGear.verified ? .blue : .gray)
                        .font(.title3)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.vertical, 2)
    }
}

struct AddGearToHikeView: View {
    @ObservedObject var hike: HikeSwiftUI
    @State private var dataService = DataService.shared
    @State private var searchText = ""
    @State private var selectedGear: Set<String> = []
    
    @Environment(\.dismiss) private var dismiss
    
    private var availableGear: [GearSwiftUI] {
        let existingGearIds = Set(hike.hikeGears.compactMap { $0.gear?.id })
        let allGear = dataService.searchGear(query: searchText).filter { gear in
            !existingGearIds.contains(gear.id)
        }
        
        // Remove duplicates by keeping only first occurrence of each gear ID
        var seenGearIds = Set<String>()
        let uniqueGear = allGear.filter { gear in
            if seenGearIds.contains(gear.id) {
                return false // This is a duplicate, filter it out
            } else {
                seenGearIds.insert(gear.id)
                return true // First occurrence, keep it
            }
        }
        
        return uniqueGear
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
            .toolbar(content: {
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
            })
        }
    }
    
    private func addSelectedGear() {
        for gearId in selectedGear {
            if let gear = dataService.gears.first(where: { $0.id == gearId }) {
                hike.addGear(gear, quantity: 1)
            }
        }
        dataService.updateHike(hike)
    }
}

#Preview {
    HikeDetailView(hike: HikeSwiftUI(name: "Sample Hike", desc: "A beautiful mountain trail"))
}