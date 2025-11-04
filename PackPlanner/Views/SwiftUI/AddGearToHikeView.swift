//
//  AddGearToHikeView.swift
//  PackPlanner
//
//  Created by Claude on SwiftUI Migration
//

import SwiftUI
import CoreData

struct AddGearToHikeView: View {
    let hike: HikeSwiftUI
    @State private var searchText = ""
    @State private var selectedGear: Set<String> = []
    @State private var gearList: [GearSwiftUI] = []
    @State private var categorizedGear: [String: [GearSwiftUI]] = [:]
    @Environment(\.dismiss) private var dismiss

    private let context = CoreDataStack.shared.viewContext
    
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
        // Load from Core Data
        let fetchRequest: NSFetchRequest<GearEntity> = GearEntity.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]

        do {
            let gearEntities = try context.fetch(fetchRequest)
            // Convert GearEntity to GearSwiftUI
            gearList = gearEntities.map { gearEntity in
                GearSwiftUI(fromCoreData: gearEntity)
            }
            categorizedGear = Dictionary(grouping: gearList) { $0.category }
        } catch {
            gearList = []
            categorizedGear = [:]
        }
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
        // Find the hike in Core Data
        let hikeFetchRequest: NSFetchRequest<HikeEntity> = HikeEntity.fetchRequest()
        hikeFetchRequest.predicate = NSPredicate(format: "name == %@", hike.name)

        do {
            guard let hikeEntity = try context.fetch(hikeFetchRequest).first else {
                dismiss()
                return
            }

            // Get existing HikeGear relationships
            let existingHikeGears = (hikeEntity.hikeGears as? Set<HikeGearEntity>) ?? []

            // Delete all existing HikeGear relationships
            for hikeGear in existingHikeGears {
                context.delete(hikeGear)
            }

            // Create new HikeGear relationships for selected gear
            for gearId in selectedGear {
                // Find the gear in Core Data
                let gearFetchRequest: NSFetchRequest<GearEntity> = GearEntity.fetchRequest()
                gearFetchRequest.predicate = NSPredicate(format: "uuid == %@", gearId)

                if let gearEntity = try context.fetch(gearFetchRequest).first {
                    let hikeGear = HikeGearEntity(context: context)
                    hikeGear.consumable = false
                    hikeGear.worn = false
                    hikeGear.numberUnits = 1
                    hikeGear.verified = false
                    hikeGear.notes = ""
                    hikeGear.gear = gearEntity
                    hikeGear.hike = hikeEntity
                }
            }

            // Save to Core Data
            try context.save()

            DispatchQueue.main.async {
                self.dismiss()
            }
        } catch {
            // Silently handle error
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