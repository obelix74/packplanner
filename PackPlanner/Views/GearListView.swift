//
//  GearListView.swift
//  PackPlanner
//
//  Created by Claude on SwiftUI Migration - With colorful category icons
//

import SwiftUI

struct GearListView: View {
    @ObservedObject private var settingsManager = SettingsManagerSwiftUI.shared
    @ObservedObject private var dataService = DataService.shared
    
    @State private var searchText = ""
    @State private var showingAddGear = false
    @State private var selectedGear: GearSwiftUI?
    @State private var showingSettings = false

    private var filteredGears: [GearSwiftUI] {
        if searchText.isEmpty {
            return dataService.gears
        }
        return dataService.gears.filter { gear in
            gear.name.localizedCaseInsensitiveContains(searchText) ||
            gear.category.localizedCaseInsensitiveContains(searchText) ||
            gear.desc.localizedCaseInsensitiveContains(searchText)
        }
    }

    private var groupedGears: [String: [GearSwiftUI]] {
        Dictionary(grouping: filteredGears) { $0.category }
    }

    private var sortedCategories: [String] {
        groupedGears.keys.sorted()
    }
    
    var body: some View {
        mainContent
            .navigationTitle("Gear")
            .navigationBarTitleDisplayMode(.large)
            .navigationBarItems(
                leading: Button(action: {
                    showingSettings = true
                }) {
                    Image(systemName: "gearshape")
                },
                trailing: Button(action: {
                    showingAddGear = true
                }) {
                    Image(systemName: "plus")
                }
            )
            .onAppear {
                dataService.loadData()
            }
            .refreshable {
                dataService.loadData()
            }
            .sheet(isPresented: $showingAddGear) {
                AddGearViewBridge()
                    .onDisappear {
                        dataService.loadData()
                    }
            }
            .sheet(item: $selectedGear) { gear in
                AddGearViewBridge(gear: gear)
                    .onDisappear {
                        dataService.loadData()
                    }
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
    }
    
    @ViewBuilder
    private var mainContent: some View {
        VStack {
            if filteredGears.isEmpty {
                emptyStateView
            } else {
                gearListView
            }
        }
    }
    
    @ViewBuilder
    private var emptyStateView: some View {
        if dataService.gears.isEmpty {
            noGearView
        } else {
            noResultsView
        }
    }
    
    private var noGearView: some View {
        VStack(spacing: 20) {
            Image(systemName: "backpack.fill")
                .font(.system(size: 60))
                .foregroundStyle(.orange)
            
            Text("No Gear Found")
                .font(.title2.bold())
                .foregroundColor(.primary)
            
            Text("Get started by adding your first piece of gear")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button(action: {
                showingAddGear = true
            }) {
                Label("Add Your First Gear", systemImage: "plus.circle.fill")
                    .font(.headline)
            }
            .buttonStyle(.borderedProminent)
            .tint(.green)
        }
        .padding()
    }
    
    private var noResultsView: some View {
        VStack(spacing: 20) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("No Results")
                .font(.title2)
                .foregroundColor(.primary)
            
            Text("Try adjusting your search")
                .font(.body)
                .foregroundColor(.secondary)
        }
        .padding()
    }
    
    private var gearListView: some View {
        List {
            ForEach(sortedCategories, id: \.self) { category in
                Section {
                    ForEach(groupedGears[category] ?? [], id: \.id) { gear in
                        gearRow(for: gear)
                    }
                } header: {
                    HStack(spacing: 8) {
                        Image(systemName: category.categoryIcon)
                            .foregroundStyle(category.categoryColor)
                            .font(.headline)
                        
                        Text(category)
                            .font(.headline)
                        
                        Spacer()
                        
                        Text("\(groupedGears[category]?.count ?? 0)")
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
        .searchable(text: $searchText, prompt: "Search gear...")
    }
    
    private func gearRow(for gear: GearSwiftUI) -> some View {
        GearRowView(
            gear: gear,
            settingsManager: settingsManager,
            categoryIcon: gear.category.categoryIcon,
            categoryColor: gear.category.categoryColor
        )
        .contentShape(Rectangle())
        .onTapGesture {
            selectedGear = gear
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(action: {
                deleteGear(gear)
            }) {
                Label("Delete", systemImage: "trash")
            }
            .tint(.red)
        }
        .swipeActions(edge: .leading, allowsFullSwipe: false) {
            Button(action: {
                duplicateGear(gear)
            }) {
                Label("Copy", systemImage: "doc.on.doc")
            }
            .tint(.blue)
        }
    }
    
    private func deleteGear(_ gear: GearSwiftUI) {
        dataService.deleteGear(gear)
    }

    private func duplicateGear(_ gear: GearSwiftUI) {
        _ = dataService.createGear(
            name: gear.name + " (Copy)",
            desc: gear.desc,
            weightInGrams: gear.weightInGrams,
            category: gear.category
        )
    }
}

struct GearRowView: View {
    let gear: GearSwiftUI
    let settingsManager: SettingsManagerSwiftUI
    let categoryIcon: String
    let categoryColor: Color
    
    var body: some View {
        HStack(spacing: 12) {
            // Colorful category icon
            Image(systemName: categoryIcon)
                .font(.title2)
                .foregroundStyle(categoryColor)
                .frame(width: 40, height: 40)
                .background(categoryColor.opacity(0.15))
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text(gear.name)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                if !gear.desc.isEmpty {
                    Text(gear.desc)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text(gear.weightString(imperial: settingsManager.isImperial))
                    .font(.subheadline.bold())
                    .foregroundColor(.primary)
                
                Text(settingsManager.weightUnit)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

#if DEBUG
struct GearListView_Previews: PreviewProvider {
    static var previews: some View {
        GearListView()
    }
}
#endif