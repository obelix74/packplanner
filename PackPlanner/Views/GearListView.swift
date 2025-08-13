//
//  GearListView.swift
//  PackPlanner
//
//  Created by Claude on SwiftUI Migration
//

import SwiftUI
import RealmSwift

struct GearListView: View {
    @StateObject private var settingsManager = SettingsManagerSwiftUI.shared
    @StateObject private var dataService = DataService.shared
    
    @State private var searchText = ""
    @State private var showingAddGear = false
    @State private var selectedGear: GearSwiftUI?
    @State private var showingSettings = false
    
    private var filteredGears: [GearSwiftUI] {
        if searchText.isEmpty {
            return dataService.gears
        } else {
            return dataService.gears.filter { gear in
                gear.name.localizedCaseInsensitiveContains(searchText) ||
                gear.desc.localizedCaseInsensitiveContains(searchText) ||
                gear.category.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    private var groupedGears: [String: [GearSwiftUI]] {
        Dictionary(grouping: filteredGears) { $0.category }
    }
    
    private var sortedCategories: [String] {
        groupedGears.keys.sorted()
    }
    
    var body: some View {
        NavigationView {
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
                    AddGearView()
                        .onDisappear {
                            dataService.loadData()
                        }
                }
                .sheet(item: $selectedGear) { gear in
                    AddGearView(gear: gear)
                        .onDisappear {
                            dataService.loadData()
                        }
                }
                .sheet(isPresented: $showingSettings) {
                    SettingsView()
                }
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
            Image(systemName: "backpack")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("No Gear Found")
                .font(.title2)
                .foregroundColor(.primary)
            
            Text("Get started by adding your first piece of gear")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button(action: {
                showingAddGear = true
            }) {
                HStack {
                    Image(systemName: "plus")
                    Text("Add Your First Gear")
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
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
                Section(header: Text(category).font(.headline)) {
                    ForEach(groupedGears[category] ?? [], id: \.id) { gear in
                        gearRow(for: gear)
                    }
                }
            }
        }
        .searchable(text: $searchText, prompt: "Search gear...")
    }
    
    private func gearRow(for gear: GearSwiftUI) -> some View {
        GearRowView(gear: gear, settingsManager: settingsManager)
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
        do {
            let realm = try Realm()
            try realm.write {
                if let realmGear = realm.objects(Gear.self).filter("uuid == %@", gear.id).first {
                    // Delete all associated HikeGear relationships first
                    let associatedHikeGears = realm.objects(HikeGear.self).filter("ANY gearList.uuid == %@", gear.id)
                    realm.delete(associatedHikeGears)
                    
                    // Then delete the gear itself
                    realm.delete(realmGear)
                }
            }
            dataService.loadData() // Refresh the list
        } catch {
            print("Error deleting gear: \(error)")
        }
    }
    
    private func duplicateGear(_ gear: GearSwiftUI) {
        do {
            let realm = try Realm()
            try realm.write {
                let newGear = Gear()
                newGear.setValues(
                    name: "\(gear.name) Copy",
                    desc: gear.desc,
                    weight: settingsManager.isImperial ? gear.weight(imperial: true) : gear.weight(imperial: false),
                    category: gear.category
                )
                realm.add(newGear)
            }
            dataService.loadData() // Refresh the list
        } catch {
            print("Error duplicating gear: \(error)")
        }
    }
}

struct GearRowView: View {
    let gear: GearSwiftUI
    let settingsManager: SettingsManagerSwiftUI
    
    var body: some View {
        HStack {
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
                    .font(.subheadline)
                    .fontWeight(.medium)
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