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
    @State private var selectedHikeForEdit: HikeSwiftUI?
    @State private var selectedHikeForDetail: HikeSwiftUI?

    private var filteredHikes: [HikeSwiftUI] {
        if searchText.isEmpty {
            return dataService.hikes
        }
        return dataService.hikes.filter { hike in
            hike.name.localizedCaseInsensitiveContains(searchText) ||
            hike.location.localizedCaseInsensitiveContains(searchText) ||
            hike.desc.localizedCaseInsensitiveContains(searchText)
        }
    }

    private var emptyStateView: some View {
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
                .padding(.horizontal)
        }
        .padding()
    }

    var body: some View {
        VStack {
            SearchBar(text: $searchText)

            if filteredHikes.isEmpty {
                emptyStateView
            } else {
                List {
                    ForEach(filteredHikes, id: \.id) { hike in
                        Button(action: {
                            selectedHikeForDetail = hike
                        }) {
                            HikeRowView(hike: hike)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button("Delete", role: .destructive) {
                                    dataService.deleteHike(hike)
                                }

                                Button("Copy") {
                                    copyHike(hike)
                                }
                                .tint(.blue)

                                Button("Edit") {
                                    selectedHikeForEdit = hike
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
                    selectedHikeForEdit = nil
                    showingAddHike = true
                }
            }
        }
        .sheet(isPresented: $showingAddHike) {
            AddHikeView(hike: selectedHikeForEdit)
                .onDisappear {
                    dataService.loadData()
                }
        }
        .sheet(item: $selectedHikeForDetail) { hike in
            HikeDetailView(hike: hike)
                .onDisappear {
                    dataService.loadData()
                }
        }
        .onAppear {
            dataService.loadData()
        }
        .refreshable {
            dataService.loadData()
        }
    }

    private func copyHike(_ hike: HikeSwiftUI) {
        _ = dataService.createHike(
            name: hike.name + " (Copy)",
            desc: hike.desc,
            distance: hike.distance,
            location: hike.location
        )
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