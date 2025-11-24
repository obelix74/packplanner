//
//  HikeDetailView.swift
//  PackPlanner
//
//  Created by Claude on SwiftUI Migration - Adaptive color design with category icons
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
    
    // Category icon helper
    private func categoryIcon(for category: String) -> String {
        switch category.lowercased() {
        case "shelter": return "tent.fill"
        case "sleeping": return "bed.double.fill"
        case "cooking": return "flame.fill"
        case "clothing": return "tshirt.fill"
        case "hygiene": return "drop.fill"
        case "electronics": return "bolt.fill"
        case "safety", "first aid": return "cross.fill"
        case "water": return "drop.triangle.fill"
        case "food": return "fork.knife"
        case "navigation": return "map.fill"
        case "tools": return "wrench.and.screwdriver.fill"
        default: return "square.grid.2x2.fill"
        }
    }
    
    // Category color helper
    private func categoryColor(for category: String) -> Color {
        switch category.lowercased() {
        case "shelter": return .pink
        case "sleeping": return .purple
        case "cooking": return .orange
        case "clothing": return .cyan
        case "hygiene": return .green
        case "electronics": return .yellow
        case "safety", "first aid": return .red
        case "water": return .blue
        case "food": return .brown
        case "navigation": return .indigo
        case "tools": return .gray
        default: return .gray
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
                        Image(systemName: "backpack.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(.orange)

                        Text(showPendingOnly ? "No Pending Items" : "No Gear Added")
                            .font(.title2.bold())
                            .foregroundColor(.primary)

                        Text(showPendingOnly ? "All items have been verified." : "Add gear to start planning this hike.")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        if !showPendingOnly {
                            Button(action: {
                                showingAddGear = true
                            }) {
                                Label("Add Gear", systemImage: "plus.circle.fill")
                                    .font(.headline)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.green)
                        }
                    }
                    .padding()
                } else {
                    List {
                        ForEach(gearByCategory.keys.sorted(), id: \.self) { category in
                            Section {
                                ForEach(gearByCategory[category] ?? [], id: \.id) { hikeGear in
                                    HikeGearRowView(
                                        hikeGear: hikeGear,
                                        hike: hike,
                                        categoryIcon: categoryIcon(for: category),
                                        categoryColor: categoryColor(for: category)
                                    )
                                    .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                                    .listRowSeparator(.hidden)
                                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                        Button("Remove", role: .destructive) {
                                            removeGear(hikeGear)
                                        }
                                    }
                                }
                            } header: {
                                HStack(spacing: 8) {
                                    Image(systemName: categoryIcon(for: category))
                                        .foregroundStyle(categoryColor(for: category))
                                        .font(.headline)
                                    
                                    Text(category)
                                        .font(.headline)
                                    
                                    Spacer()
                                    
                                    Text("\(gearByCategory[category]?.count ?? 0)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color.secondary.opacity(0.15))
                                        .cornerRadius(8)
                                }
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
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
                    Button(action: {
                        showingAddGear = true
                    }) {
                        Image(systemName: "plus")
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
        VStack(alignment: .leading, spacing: 16) {
            if !hike.desc.isEmpty {
                Text(hike.desc)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            HStack(spacing: 16) {
                if !hike.location.isEmpty {
                    Label(hike.location, systemImage: "location.fill")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                if !hike.distance.isEmpty {
                    Label(hike.distance, systemImage: "figure.hiking")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            // Weight summary with colorful cards
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                WeightSummaryCard(
                    icon: "backpack.fill",
                    title: "Total Weight",
                    weight: hike.totalWeight,
                    color: .indigo
                )
                
                WeightSummaryCard(
                    icon: "scalemass.fill",
                    title: "Base Weight",
                    weight: hike.baseWeight,
                    color: .blue
                )
                
                WeightSummaryCard(
                    icon: "tshirt.fill",
                    title: "Worn Weight",
                    weight: hike.wornWeight,
                    color: .green
                )
                
                WeightSummaryCard(
                    icon: "leaf.fill",
                    title: "Consumable",
                    weight: hike.consumableWeight,
                    color: .orange
                )
            }
        }
        .padding()
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .cornerRadius(12)
        .padding()
    }
}

struct WeightSummaryCard: View {
    let icon: String
    let title: String
    let weight: Double
    let color: Color
    @StateObject private var settingsManager = SettingsManagerSwiftUI.shared
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(settingsManager.formatWeight(weight))
                .font(.headline.bold())
                .foregroundColor(.primary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(color.opacity(0.15))
        .cornerRadius(12)
    }
}

struct HikeGearRowView: View {
    @ObservedObject var hikeGear: HikeGearSwiftUI
    let hike: HikeSwiftUI
    let categoryIcon: String
    let categoryColor: Color
    @StateObject private var dataService = DataService.shared
    @StateObject private var settingsManager = SettingsManagerSwiftUI.shared

    var body: some View {
        HStack(spacing: 12) {
            // Colorful category icon
            Image(systemName: categoryIcon)
                .font(.title3)
                .foregroundStyle(categoryColor)
                .frame(width: 36, height: 36)
                .background(categoryColor.opacity(0.15))
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text(hikeGear.gear?.name ?? "Unknown Gear")
                    .font(.headline)
                    .foregroundColor(.primary)

                if let desc = hikeGear.gear?.desc, !desc.isEmpty {
                    Text(desc)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }

                HStack(spacing: 12) {
                    Text("Qty: \(hikeGear.numberUnits)")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text(hikeGear.weightString(imperial: settingsManager.isImperial))
                        .font(.caption.bold())
                        .foregroundColor(.primary)
                }
            }

            Spacer()

            HStack(spacing: 12) {
                Button(action: {
                    hikeGear.worn.toggle()
                    hike.invalidateWeightCache()
                    hike.objectWillChange.send()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                        dataService.updateHike(hike)
                    }
                }) {
                    Image(systemName: hikeGear.worn ? "tshirt.fill" : "tshirt")
                        .foregroundColor(hikeGear.worn ? .green : .secondary)
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
                        .foregroundColor(hikeGear.consumable ? .orange : .secondary)
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
                        .foregroundColor(hikeGear.verified ? .blue : .secondary)
                        .font(.title3)
                }
                .buttonStyle(.borderless)
            }
        }
        .padding()
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .cornerRadius(12)
    }
}


#Preview {
    HikeDetailView(hike: HikeSwiftUI(name: "Sample Hike", desc: "A beautiful mountain trail"))
}