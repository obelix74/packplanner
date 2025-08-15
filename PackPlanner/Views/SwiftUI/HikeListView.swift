//
//  HikeListView.swift
//  PackPlanner
//
//  Created by Claude on SwiftUI Migration
//

import SwiftUI

struct HikeListView: View {
    @StateObject private var dataService = DataService.shared
    @StateObject private var settingsManager = SettingsManagerSwiftUI.shared
    @State private var searchText = ""
    @State private var showingAddHike = false
    @State private var selectedHike: HikeSwiftUI?
    @State private var showingHikeDetail = false
    
    private let hikeLogic = HikeListLogic.shared
    
    private var filteredHikes: [HikeSwiftUI] {
        // Use shared search logic
        return hikeLogic.performSearch(items: dataService.hikes, query: searchText)
    }
    
    var body: some View {
        NavigationView {
            VStack {
                SearchBar(text: $searchText)
                
                if filteredHikes.isEmpty {
                    ContentUnavailableView(
                        "No Hikes Found",
                        systemImage: "mountain.2",
                        description: Text("Plan your first hiking adventure by adding a new hike.")
                    )
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
                                        // Use shared hike logic
                                        hikeLogic.deleteHike(hike) { _ in }
                                    }
                                    
                                    Button("Copy") {
                                        // Use shared hike logic
                                        hikeLogic.copyHike(hike)
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
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        selectedHike = nil
                        showingAddHike = true
                    }
                }
            }
            .sheet(isPresented: $showingAddHike) {
                AddHikeView(hike: selectedHike)
                    .onDisappear {
                        dataService.loadData()
                    }
            }
            .sheet(isPresented: $showingHikeDetail) {
                if let hike = selectedHike {
                    HikeDetailView(hike: hike)
                }
            }
            .onAppear {
                dataService.loadData()
            }
            .refreshable {
                dataService.loadData()
            }
        }
    }
}

struct HikeRowView: View {
    let hike: HikeSwiftUI
    @StateObject private var settingsManager = SettingsManagerSwiftUI.shared
    
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