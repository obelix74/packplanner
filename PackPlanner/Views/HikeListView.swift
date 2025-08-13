//
//  HikeListView.swift
//  PackPlanner
//
//  Created by Claude on SwiftUI Migration
//

import SwiftUI

struct HikeListView: View {
    @State private var dataService = DataService.shared
    @State private var settingsManager = SettingsManagerSwiftUI.shared
    @State private var searchText = ""
    @State private var showingAddHike = false
    @State private var selectedHike: HikeSwiftUI?
    @State private var showingHikeDetail = false
    
    private var filteredHikes: [HikeSwiftUI] {
        dataService.searchHikes(query: searchText)
    }
    
    var body: some View {
        NavigationView {
            VStack {
                SearchBar(text: $searchText)
                
                if filteredHikes.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "mountain.2")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        
                        Text("No Hikes Found")
                            .font(.title2)
                            .foregroundColor(.primary)
                        
                        Text("Plan your first hiking adventure by adding a new hike.")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                } else {
                    List {
                        ForEach(filteredHikes, id: \.id) { hike in
                            HikeRowView(hike: hike)
                                .onTapGesture {
                                    selectedHike = hike
                                    showingHikeDetail = true
                                }
                                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                    Button("Delete", role: .destructive) {
                                        dataService.deleteHike(hike)
                                    }
                                    
                                    Button("Copy") {
                                        let copiedHike = dataService.copyHike(hike)
                                        dataService.addHike(copiedHike)
                                    }
                                    .tint(.blue)
                                    
                                    Button("Edit") {
                                        selectedHike = hike
                                        showingAddHike = true
                                    }
                                    .tint(.orange)
                                }
                        }
                    }
                }
            }
            .navigationTitle("Hikes")
            .navigationBarItems(
                trailing: Button("Add") {
                    selectedHike = nil
                    showingAddHike = true
                }
            )
            .sheet(isPresented: $showingAddHike) {
                AddHikeView(hike: selectedHike)
            }
            .sheet(isPresented: $showingHikeDetail) {
                if let hike = selectedHike {
                    HikeDetailView(hike: hike)
                }
            }
        }
    }
}

struct HikeRowView: View {
    let hike: HikeSwiftUI
    @State private var settingsManager = SettingsManagerSwiftUI.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(hike.name)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                if hike.completed {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                }
            }
            
            if !hike.desc.isEmpty {
                Text(hike.desc)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
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
                
                if !hike.hikeGears.isEmpty {
                    Text("\(hike.hikeGears.count) items")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(settingsManager.formatWeight(hike.totalWeight))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    HikeListView()
}