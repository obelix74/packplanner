//
//  AddGearToHikeView.swift
//  PackPlanner
//
//  Created by Claude on SwiftUI Migration
//

import SwiftUI

struct AddGearToHikeView: View {
    let hike: HikeSwiftUI
    @State private var searchText = ""
    @State private var selectedGear: Set<String> = []
    @State private var gearList: [GearSwiftUI] = []
    @State private var categorizedGear: [String: [GearSwiftUI]] = [:]
    @Environment(\.dismiss) private var dismiss
    
    private var dataService = DataService.shared
    
    var body: some View {
        NavigationView {
            VStack {
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    
                    TextField("Search gear...", text: $searchText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                .padding()
                
                // Gear List
                List {
                    ForEach(sortedCategories, id: \.self) { category in
                        Section(header: Text(category).font(.headline)) {
                            ForEach(filteredGear(for: category), id: \.id) { gear in
                                GearSelectionRow(
                                    gear: gear,
                                    isSelected: selectedGear.contains(gear.id)
                                ) {
                                    toggleGearSelection(gear)
                                }
                            }
                        }
                    }
                }
                .listStyle(PlainListStyle())
            }
            .navigationTitle("Add Gear to \(hike.name)")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.blue)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveSelectedGear()
                    }
                    .foregroundColor(.blue)
                    .fontWeight(.semibold)
                }
            }
        }
        .onAppear {
            loadGear()
            loadExistingGearSelections()
        }
    }
    
    private var sortedCategories: [String] {
        return categorizedGear.keys.sorted()
    }
    
    private func filteredGear(for category: String) -> [GearSwiftUI] {
        let categoryGear = categorizedGear[category] ?? []
        
        if searchText.isEmpty {
            return categoryGear
        } else {
            return categoryGear.filter { gear in
                gear.name.localizedCaseInsensitiveContains(searchText) ||
                gear.desc.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    private func loadGear() {
        // Clean up any duplicate gears first
        GearBrain.cleanupDuplicateGears()
        
        // Reload data from DataService to ensure fresh data
        dataService.loadData()
        gearList = dataService.gears
        categorizedGear = Dictionary(grouping: gearList) { $0.category }
    }
    
    private func loadExistingGearSelections() {
        // Mark gear that's already associated with this hike
        selectedGear = Set(hike.hikeGears.compactMap { $0.gear?.id })
    }
    
    private func toggleGearSelection(_ gear: GearSwiftUI) {
        if selectedGear.contains(gear.id) {
            selectedGear.remove(gear.id)
        } else {
            selectedGear.insert(gear.id)
        }
    }
    
    private func saveSelectedGear() {
        print("🔵 DEBUG: saveSelectedGear() called")
        print("🔵 DEBUG: selectedGear count: \(selectedGear.count)")
        print("🔵 DEBUG: hike.hikeGears count before: \(hike.hikeGears.count)")
        print("🔵 DEBUG: hike.id: \(hike.id)")
        print("🔵 DEBUG: hike.name: \(hike.name)")
        
        // Create HikeGear relationships for selected gear
        var updatedHikeGears: [HikeGearSwiftUI] = []
        
        // Keep existing gear that's still selected
        for existingHikeGear in hike.hikeGears {
            if let gearId = existingHikeGear.gear?.id, selectedGear.contains(gearId) {
                print("🔵 DEBUG: Keeping existing gear: \(existingHikeGear.gear?.name ?? "unknown")")
                updatedHikeGears.append(existingHikeGear)
            } else {
                print("🔵 DEBUG: Removing gear: \(existingHikeGear.gear?.name ?? "unknown")")
            }
        }
        
        // Add new gear selections
        for gearId in selectedGear {
            let alreadyExists = hike.hikeGears.contains { $0.gear?.id == gearId }
            if !alreadyExists, let gear = gearList.first(where: { $0.id == gearId }) {
                print("🔵 DEBUG: Adding new gear: \(gear.name)")
                let hikeGear = HikeGearSwiftUI()
                hikeGear.gear = gear
                hikeGear.consumable = false
                hikeGear.worn = false
                hikeGear.numberUnits = 1
                hikeGear.verified = false
                hikeGear.notes = ""
                updatedHikeGears.append(hikeGear)
            } else if alreadyExists {
                print("🔵 DEBUG: Gear already exists, skipping: \(gear?.name ?? "unknown")")
            }
        }
        
        print("🔵 DEBUG: updatedHikeGears count: \(updatedHikeGears.count)")
        
        // Update the hike with new gear list
        let updatedHike = hike
        updatedHike.hikeGears = updatedHikeGears
        
        print("🔵 DEBUG: hike.hikeGears count after update: \(hike.hikeGears.count)")
        print("🔵 DEBUG: Calling dataService.updateHike()")
        
        // Save to DataService with completion handler
        dataService.updateHike(updatedHike) {
            print("🔵 DEBUG: DataService.updateHike() completion called")
            DispatchQueue.main.async {
                print("🔵 DEBUG: saveSelectedGear() completed, dismissing")
                self.dismiss()
            }
        }
    }
}

struct GearSelectionRow: View {
    let gear: GearSwiftUI
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(gear.name)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                if !gear.desc.isEmpty {
                    Text(gear.desc)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                Text(formatWeight(gear.weightInGrams))
                    .font(.caption)
                    .foregroundColor(.blue)
            }
            
            Spacer()
            
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.blue)
                    .font(.title3)
            } else {
                Image(systemName: "circle")
                    .foregroundColor(.secondary)
                    .font(.title3)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            onTap()
        }
        .padding(.vertical, 4)
    }
    
    private func formatWeight(_ weightInGrams: Double) -> String {
        let settings = SettingsManagerSwiftUI.shared.settings
        
        if settings.useImperialUnits {
            let ounces = weightInGrams * 0.035274
            return String(format: "%.2f oz", ounces)
        } else {
            return String(format: "%.1f g", weightInGrams)
        }
    }
}

struct AddGearToHikeView_Previews: PreviewProvider {
    static var previews: some View {
        let sampleHike = HikeSwiftUI()
        sampleHike.name = "Sample Hike"
        sampleHike.desc = "A sample hike for preview"
        sampleHike.location = "Sample Location"
        sampleHike.distance = 10.5
        
        return AddGearToHikeView(hike: sampleHike)
    }
}