//
//  HikeListView.swift
//  PackPlanner
//
//  Created by Claude on SwiftUI Migration - Adaptive color design
//

import SwiftUI

struct HikeListView: View {
    @ObservedObject private var dataService = DataService.shared
    @ObservedObject private var settingsManager = SettingsManagerSwiftUI.shared
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
            Image(systemName: "mountain.2.fill")
                .font(.system(size: 70))
                .foregroundStyle(.green)

            Text("No Hikes Found")
                .font(.title2.bold())
                .foregroundColor(.primary)

            Text("Plan your first hiking adventure by adding a new hike.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button(action: {
                selectedHikeForEdit = nil
                showingAddHike = true
            }) {
                Label("Add Your First Hike", systemImage: "plus.circle.fill")
                    .font(.headline)
            }
            .buttonStyle(.borderedProminent)
            .tint(.green)
        }
        .padding()
    }

    var body: some View {
        VStack(spacing: 0) {
            SearchBar(text: $searchText)
                .padding()

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
                        .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                        .listRowSeparator(.hidden)
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
                .listStyle(.plain)
            }
        }
        .navigationTitle("Hikes")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    selectedHikeForEdit = nil
                    showingAddHike = true
                }) {
                    Image(systemName: "plus")
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
    @ObservedObject private var settingsManager = SettingsManagerSwiftUI.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                // Hike icon
                Image(systemName: "mountain.2.fill")
                    .font(.title2)
                    .foregroundStyle(.green)
                    .frame(width: 44, height: 44)
                    .background(Color.green.opacity(0.15))
                    .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(hike.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    if !hike.desc.isEmpty {
                        Text(hike.desc)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
                
                Spacer()
                
                if hike.completed {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.title2)
                        .foregroundStyle(.green)
                }
            }
            
            // Info row
            HStack(spacing: 16) {
                if !hike.location.isEmpty {
                    Label(hike.location, systemImage: "location.fill")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                if !hike.distance.isEmpty {
                    Label(hike.distance, systemImage: "figure.hiking")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            // Weight summary
            if !hike.hikeGears.isEmpty {
                HStack(spacing: 12) {
                    WeightBadge(
                        icon: "backpack.fill",
                        value: settingsManager.formatWeight(hike.totalWeight),
                        color: .indigo
                    )
                    
                    WeightBadge(
                        icon: "scalemass.fill",
                        value: settingsManager.formatWeight(hike.baseWeight),
                        color: .blue
                    )
                    
                    Text("\(hike.hikeGears.count) items")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.secondary.opacity(0.15))
                        .cornerRadius(8)
                    
                    Spacer()
                }
            }
        }
        .padding()
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .cornerRadius(12)
    }
}

struct WeightBadge: View {
    let icon: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(color)
            
            Text(value)
                .font(.caption.bold())
                .foregroundColor(.primary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.15))
        .cornerRadius(8)
    }
}

#Preview {
    NavigationView {
        HikeListView()
    }
}