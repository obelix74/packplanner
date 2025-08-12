//
//  GearListView.swift
//  PackPlanner
//
//  Created by Claude on SwiftUI Migration
//

import SwiftUI

struct GearListView: View {
    @State private var dataService = DataService.shared
    @State private var settingsManager = SettingsManagerSwiftUI.shared
    @State private var searchText = ""
    @State private var showingAddGear = false
    @State private var selectedGear: GearSwiftUI?
    @State private var showingGearDetail = false
    
    private var filteredGear: [GearSwiftUI] {
        dataService.searchGear(query: searchText)
    }
    
    private var gearByCategory: [String: [GearSwiftUI]] {
        Dictionary(grouping: filteredGear) { $0.category }
    }
    
    var body: some View {
        NavigationView {
            VStack {
                SearchBar(text: $searchText)
                
                if filteredGear.isEmpty {
                    ContentUnavailableView(
                        "No Gear Found",
                        systemImage: "backpack",
                        description: Text("Add some gear to get started with your packing lists.")
                    )
                } else {
                    List {
                        ForEach(gearByCategory.keys.sorted(), id: \.self) { category in
                            Section(category) {
                                ForEach(gearByCategory[category] ?? [], id: \.id) { gear in
                                    GearRowView(gear: gear)
                                        .onTapGesture {
                                            selectedGear = gear
                                            showingGearDetail = true
                                        }
                                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                            Button("Delete", role: .destructive) {
                                                dataService.deleteGear(gear)
                                            }
                                            
                                            Button("Edit") {
                                                selectedGear = gear
                                                showingAddGear = true
                                            }
                                            .tint(.blue)
                                        }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Gear")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        selectedGear = nil
                        showingAddGear = true
                    }
                }
            }
            .sheet(isPresented: $showingAddGear) {
                AddGearView(gear: selectedGear)
            }
            .sheet(isPresented: $showingGearDetail) {
                if let gear = selectedGear {
                    GearDetailView(gear: gear)
                }
            }
        }
    }
}

struct GearRowView: View {
    let gear: GearSwiftUI
    @State private var settingsManager = SettingsManagerSwiftUI.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(gear.name)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text(gear.weightString(imperial: settingsManager.isImperial))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            if !gear.desc.isEmpty {
                Text(gear.desc)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            Text(gear.category)
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .background(Color.blue.opacity(0.1))
                .foregroundColor(.blue)
                .clipShape(Capsule())
        }
        .padding(.vertical, 2)
    }
}

struct SearchBar: View {
    @Binding var text: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            
            TextField("Search gear...", text: $text)
                .textFieldStyle(RoundedBorderTextFieldStyle())
        }
        .padding(.horizontal)
    }
}

struct GearDetailView: View {
    let gear: GearSwiftUI
    @State private var settingsManager = SettingsManagerSwiftUI.shared
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Name")
                        .font(.headline)
                    Text(gear.name)
                        .font(.body)
                }
                
                if !gear.desc.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Description")
                            .font(.headline)
                        Text(gear.desc)
                            .font(.body)
                    }
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Weight")
                        .font(.headline)
                    Text(gear.weightString(imperial: settingsManager.isImperial))
                        .font(.body)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Category")
                        .font(.headline)
                    Text(gear.category)
                        .font(.body)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.1))
                        .foregroundColor(.blue)
                        .clipShape(Capsule())
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Gear Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    GearListView()
}