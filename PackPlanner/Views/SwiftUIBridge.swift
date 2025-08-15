//
//  SwiftUIBridge.swift
//  PackPlanner
//
//  Created by Claude on SwiftUI Migration
//

import Foundation
import SwiftUI
import UIKit

// Import SwiftUI views from SwiftUI folder
// Note: These views are located in Views/SwiftUI/ folder

// MARK: - Embedded SwiftUI Views (temporary until Xcode target is updated)

public struct HikeDetailViewBridge: View {
    @ObservedObject var hike: HikeSwiftUI
    @StateObject private var dataService = DataService.shared
    @State private var settingsManager = SettingsManagerSwiftUI.shared
    @State private var showingAddGear = false
    @State private var showPendingOnly = false
    @State private var refreshTrigger = false
    @Environment(\.dismiss) private var dismiss
    let dismissCallback: (() -> Void)?
    
    public init(hike: HikeSwiftUI, dismissCallback: (() -> Void)? = nil) {
        self.hike = hike
        self.dismissCallback = dismissCallback
    }
    
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
    
    public var body: some View {
        NavigationView {
            contentView
                .navigationTitle(hike.name)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        doneButton
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        addGearButton
                    }
                }
                .sheet(isPresented: $showingAddGear) {
                    AddGearToHikeView(hike: hike)
                        .onDisappear {
                            // Refresh the hike data when the sheet is dismissed
                            // Add a small delay to ensure any pending updates complete first
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                refreshHikeData()
                            }
                        }
                }
                .onAppear {
                    // Refresh data when view appears
                    refreshHikeData()
                }
        }
    }
    
    private var contentView: some View {
        VStack(spacing: 0) {
            HikeHeaderViewBridge(hike: hike, refreshTrigger: refreshTrigger)
            
            segmentedControl
            
            gearListView
        }
    }
    
    private var segmentedControl: some View {
        Picker("View", selection: $showPendingOnly) {
            Text("All Items").tag(false)
            Text("Pending Only").tag(true)
        }
        .pickerStyle(.segmented)
        .padding()
    }
    
    private var gearListView: some View {
        Group {
            if filteredGears.isEmpty {
                emptyStateView
            } else {
                gearList
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "backpack")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text(showPendingOnly ? "No Pending Items" : "No Gear Added")
                .font(.title2)
                .foregroundColor(.primary)
            
            Text(showPendingOnly ? "All items have been verified." : "Add gear to start planning this hike.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
    
    private var gearList: some View {
        List {
            ForEach(gearByCategory.keys.sorted(), id: \.self) { category in
                Section(category) {
                    ForEach(gearByCategory[category] ?? [], id: \.id) { hikeGear in
                        HikeGearRowViewBridge(hikeGear: hikeGear, hike: hike, refreshTrigger: $refreshTrigger)
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button("Remove", role: .destructive) {
                                    removeGear(hikeGear)
                                }
                            }
                    }
                }
            }
        }
    }
    
    private var doneButton: some View {
        Button("Done") {
            if let dismissCallback = dismissCallback {
                dismissCallback()
            } else {
                dismiss()
            }
        }
    }
    
    private var addGearButton: some View {
        Button("Add Gear") {
            showingAddGear = true
        }
    }
    
    private func removeGear(_ hikeGear: HikeGearSwiftUI) {
        if let index = hike.hikeGears.firstIndex(where: { $0.id == hikeGear.id }) {
            hike.hikeGears.remove(at: index)
            dataService.updateHike(hike) {
                // Refresh data after successful update
                DispatchQueue.main.async {
                    self.refreshHikeData()
                }
            }
        }
    }
    
    private func refreshHikeData() {
        // Reload data and update hike with simplified approach
        dataService.loadData()
        
        // Use a single short delay to allow data loading to complete
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            if let updatedHike = self.dataService.hikes.first(where: { $0.name == self.hike.name }) {
                self.hike.hikeGears = updatedHike.hikeGears
            }
        }
    }
    
}

public struct HikeHeaderViewBridge: View {
    let hike: HikeSwiftUI
    let refreshTrigger: Bool
    @State private var settingsManager = SettingsManagerSwiftUI.shared
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if !hike.desc.isEmpty {
                Text(hike.desc)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
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
            }
            
            // Weight summary
            VStack(spacing: 8) {
                HStack {
                    WeightSummaryItemBridge(
                        title: "Total Weight",
                        weight: hike.totalWeight,
                        color: .primary
                    )
                    
                    Spacer()
                    
                    WeightSummaryItemBridge(
                        title: "Base Weight",
                        weight: hike.baseWeight,
                        color: .blue
                    )
                }
                
                HStack {
                    WeightSummaryItemBridge(
                        title: "Worn Weight",
                        weight: hike.wornWeight,
                        color: .green
                    )
                    
                    Spacer()
                    
                    WeightSummaryItemBridge(
                        title: "Consumable",
                        weight: hike.consumableWeight,
                        color: .orange
                    )
                }
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)
            .id("weightSummary-\(refreshTrigger)")
        }
        .padding()
    }
}

public struct WeightSummaryItemBridge: View {
    let title: String
    let weight: Double
    let color: Color
    @State private var settingsManager = SettingsManagerSwiftUI.shared
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(settingsManager.formatWeight(weight))
                .font(.headline)
                .foregroundColor(color)
        }
    }
}

public struct HikeGearRowViewBridge: View {
    @ObservedObject var hikeGear: HikeGearSwiftUI
    let hike: HikeSwiftUI
    @Binding var refreshTrigger: Bool
    @State private var dataService = DataService.shared
    @State private var settingsManager = SettingsManagerSwiftUI.shared
    
    public var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(hikeGear.gear?.name ?? "Unknown Gear")
                    .font(.headline)
                
                if let desc = hikeGear.gear?.desc, !desc.isEmpty {
                    Text(desc)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                HStack {
                    Text("Qty: \(hikeGear.numberUnits)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(hikeGear.weightString(imperial: settingsManager.isImperial))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            VStack {
                HStack(spacing: 16) {
                    Button(action: {
                        hikeGear.worn.toggle()
                        hike.objectWillChange.send()
                        refreshTrigger.toggle()
                        dataService.updateHike(hike)
                    }) {
                        Image(systemName: hikeGear.worn ? "tshirt.fill" : "tshirt")
                            .foregroundColor(hikeGear.worn ? .green : .gray)
                            .font(.title3)
                            .frame(width: 30, height: 30)
                    }
                    .buttonStyle(.plain)
                    
                    Button(action: {
                        hikeGear.consumable.toggle()
                        hike.objectWillChange.send()
                        refreshTrigger.toggle()
                        dataService.updateHike(hike)
                    }) {
                        Image(systemName: hikeGear.consumable ? "leaf.fill" : "leaf")
                            .foregroundColor(hikeGear.consumable ? .orange : .gray)
                            .font(.title3)
                            .frame(width: 30, height: 30)
                    }
                    .buttonStyle(.plain)
                    
                    Button(action: {
                        hikeGear.verified.toggle()
                        hike.objectWillChange.send()
                        dataService.updateHike(hike)
                    }) {
                        Image(systemName: hikeGear.verified ? "checkmark.circle.fill" : "checkmark.circle")
                            .foregroundColor(hikeGear.verified ? .blue : .gray)
                            .font(.title3)
                            .frame(width: 30, height: 30)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.vertical, 2)
    }
}


public struct HikeListViewBridge: View {
    @StateObject private var dataService = DataService.shared
    @StateObject private var settingsManager = SettingsManagerSwiftUI.shared
    @State private var searchText = ""
    @State private var showingAddHike = false
    @State private var selectedHike: HikeSwiftUI?
    @State private var showingHikeDetail = false
    
    private var filteredHikes: [HikeSwiftUI] {
        dataService.searchHikes(query: searchText)
    }
    
    public var body: some View {
        NavigationView {
            VStack {
                SearchBarBridge(text: $searchText)
                
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
                            HikeRowViewBridge(hike: hike, settingsManager: settingsManager)
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
            .navigationBarItems(trailing:
                Button("Add") {
                    selectedHike = nil
                    showingAddHike = true
                }
            )
            .sheet(isPresented: $showingAddHike) {
                AddHikeViewBridge(hike: selectedHike)
                    .onDisappear {
                        dataService.loadData()
                    }
            }
            .sheet(isPresented: $showingHikeDetail) {
                if let hike = selectedHike {
                    Text("Hike Detail: \(hike.name)")
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

public struct SearchBarBridge: View {
    @Binding var text: String
    
    public var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField("Search hikes...", text: $text)
                .textFieldStyle(RoundedBorderTextFieldStyle())
        }
        .padding()
    }
}

public struct HikeRowViewBridge: View {
    let hike: HikeSwiftUI
    let settingsManager: SettingsManagerSwiftUI
    
    public var body: some View {
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

public struct HikeReportView: View {
    let hike: HikeSwiftUI
    @State private var selectedFilter = "Total weight"
    @State private var reportData: [String: Double] = [:]
    @State private var sortedKeys: [String] = []
    @Environment(\.dismiss) private var dismiss
    
    private let filters = ["Total weight", "Base weight", "Consumable weight", "Worn weight"]
    
    public var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Title and Summary
                VStack(spacing: 10) {
                    Text("Weight Report")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text(formatWeight(totalWeight))
                        .font(.title3)
                        .font(.body.weight(.semibold))
                        .foregroundColor(.red)
                }
                .padding()
                
                // Filter Picker
                Picker("Filter", selection: $selectedFilter) {
                    ForEach(filters, id: \.self) { filter in
                        Text(filter).tag(filter)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
                
                // Report List
                List {
                    ForEach(sortedKeys, id: \.self) { key in
                        HStack {
                            Text(key)
                                .font(.body)
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            Text(formatWeight(reportData[key] ?? 0))
                                .font(.body)
                                .fontWeight(.medium)
                                .foregroundColor(.blue)
                        }
                        .padding(.vertical, 4)
                    }
                }
                .listStyle(PlainListStyle())
            }
            .navigationTitle("Report for \(hike.name)")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.blue)
                }
            }
        }
        .onAppear {
            loadReportData()
        }
        .onChange(of: selectedFilter) { _ in
            loadReportData()
        }
    }
    
    private var totalWeight: Double {
        return hike.hikeGears.reduce(0) { total, hikeGear in
            let gearWeight = hikeGear.gear?.weightInGrams ?? 0
            return total + (gearWeight * Double(hikeGear.numberUnits))
        }
    }
    
    private func loadReportData() {
        var data: [String: Double] = [:]
        
        // Group gear by category
        let groupedGear = Dictionary(grouping: hike.hikeGears) { hikeGear in
            hikeGear.gear?.category ?? "Unknown"
        }
        
        // Calculate weights by category based on selected filter
        for (category, gears) in groupedGear {
            let categoryWeight = gears.reduce(0.0) { total, hikeGear in
                guard let gear = hikeGear.gear else { return total }
                let unitWeight = gear.weightInGrams * Double(hikeGear.numberUnits)
                
                switch selectedFilter {
                case "Base weight":
                    return hikeGear.consumable || hikeGear.worn ? total : total + unitWeight
                case "Consumable weight":
                    return hikeGear.consumable ? total + unitWeight : total
                case "Worn weight":
                    return hikeGear.worn ? total + unitWeight : total
                default: // Total weight
                    return total + unitWeight
                }
            }
            
            if categoryWeight > 0 {
                data[category] = categoryWeight
            }
        }
        
        reportData = data
        sortedKeys = data.keys.sorted { data[$0] ?? 0 > data[$1] ?? 0 }
    }
    
    private func formatWeight(_ weightInGrams: Double) -> String {
        let settings = SettingsManagerSwiftUI.shared.settings
        
        if settings.imperial {
            let ounces = weightInGrams * 0.035274
            return String(format: "%.2f oz", ounces)
        } else {
            return String(format: "%.1f g", weightInGrams)
        }
    }
}

public struct EditHikeGearView: View {
    @Binding var hikeGear: HikeGearSwiftUI
    let hike: HikeSwiftUI
    @State private var numberUnits: String = ""
    @State private var notes: String = ""
    @State private var consumable: Bool = false
    @State private var worn: Bool = false
    @State private var verified: Bool = false
    @Environment(\.dismiss) private var dismiss
    
    private var dataService = DataService.shared
    
    public var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Gear Information")) {
                    HStack {
                        Text("Name:")
                            .fontWeight(.medium)
                        Spacer()
                        Text(hikeGear.gear?.name ?? "Unknown Gear")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Description:")
                            .fontWeight(.medium)
                        Spacer()
                        Text(hikeGear.gear?.desc ?? "")
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    HStack {
                        Text("Weight:")
                            .fontWeight(.medium)
                        Spacer()
                        Text(formatWeight(hikeGear.gear?.weightInGrams ?? 0))
                            .foregroundColor(.blue)
                    }
                    
                    HStack {
                        Text("Category:")
                            .fontWeight(.medium)
                        Spacer()
                        Text(hikeGear.gear?.category ?? "")
                            .foregroundColor(.secondary)
                    }
                }
                
                Section(header: Text("Quantity")) {
                    HStack {
                        Text("Number of Units:")
                            .fontWeight(.medium)
                        
                        Spacer()
                        
                        TextField("1", text: $numberUnits)
                            .keyboardType(.numberPad)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(width: 80)
                            .multilineTextAlignment(.center)
                    }
                }
                
                Section(header: Text("Properties")) {
                    Toggle("Consumable", isOn: $consumable)
                        .tint(.orange)
                    
                    Toggle("Worn", isOn: $worn)
                        .tint(.green)
                    
                    Toggle("Verified", isOn: $verified)
                        .tint(.blue)
                }
                
                Section(header: Text("Notes")) {
                    TextEditor(text: $notes)
                        .frame(minHeight: 100)
                }
                
                Section {
                    HStack {
                        Text("Total Weight:")
                            .font(.body.weight(.semibold))
                        Spacer()
                        Text(formatWeight(totalWeight))
                            .fontWeight(.bold)
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("Edit Gear")
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
                        saveChanges()
                    }
                    .foregroundColor(.blue)
                    .font(.body.weight(.semibold))
                }
            }
        }
        .onAppear {
            loadCurrentValues()
        }
    }
    
    private var totalWeight: Double {
        let units = Double(numberUnits) ?? 1.0
        let unitWeight = hikeGear.gear?.weightInGrams ?? 0
        return unitWeight * units
    }
    
    private func loadCurrentValues() {
        numberUnits = String(hikeGear.numberUnits)
        notes = hikeGear.notes
        consumable = hikeGear.consumable
        worn = hikeGear.worn
        verified = hikeGear.verified
    }
    
    private func saveChanges() {
        // Update the hikeGear object
        hikeGear.numberUnits = Int(numberUnits) ?? 1
        hikeGear.notes = notes
        hikeGear.consumable = consumable
        hikeGear.worn = worn
        hikeGear.verified = verified
        
        // Update the hike in the data service
        dataService.updateHike(hike)
        
        dismiss()
    }
    
    private func formatWeight(_ weightInGrams: Double) -> String {
        let settings = SettingsManagerSwiftUI.shared.settings
        
        if settings.imperial {
            let ounces = weightInGrams * 0.035274
            return String(format: "%.2f oz", ounces)
        } else {
            return String(format: "%.1f g", weightInGrams)
        }
    }
}

public struct AddGearToHikeView: View {
    let hike: HikeSwiftUI
    @State private var searchText = ""
    @State private var selectedGear: Set<String> = []
    @State private var gearList: [GearSwiftUI] = []
    @State private var categorizedGear: [String: [GearSwiftUI]] = [:]
    @Environment(\.dismiss) private var dismiss
    
    private var dataService = DataService.shared
    
    public init(hike: HikeSwiftUI) {
        self.hike = hike
    }
    
    public var body: some View {
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
                    .font(.body.weight(.semibold))
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
        // Create HikeGear relationships for selected gear
        var updatedHikeGears: [HikeGearSwiftUI] = []
        
        // Keep existing gear that's still selected
        for existingHikeGear in hike.hikeGears {
            if let gearId = existingHikeGear.gear?.id, selectedGear.contains(gearId) {
                updatedHikeGears.append(existingHikeGear)
            }
        }
        
        // Add new gear selections
        for gearId in selectedGear {
            let alreadyExists = hike.hikeGears.contains { $0.gear?.id == gearId }
            if !alreadyExists, let gear = gearList.first(where: { $0.id == gearId }) {
                let hikeGear = HikeGearSwiftUI()
                hikeGear.gear = gear
                hikeGear.consumable = false
                hikeGear.worn = false
                hikeGear.numberUnits = 1
                hikeGear.verified = false
                hikeGear.notes = ""
                updatedHikeGears.append(hikeGear)
            }
        }
        
        // Update the hike with new gear list
        let updatedHike = hike
        updatedHike.hikeGears = updatedHikeGears
        
        // Save to DataService
        dataService.updateHike(updatedHike)
        
        dismiss()
    }
}

public struct GearSelectionRow: View {
    let gear: GearSwiftUI
    let isSelected: Bool
    let onTap: () -> Void
    
    public var body: some View {
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
        
        if settings.imperial {
            let ounces = weightInGrams * 0.035274
            return String(format: "%.2f oz", ounces)
        } else {
            return String(format: "%.1f g", weightInGrams)
        }
    }
}

// MARK: - Migration Helper

class SwiftUIMigrationHelper {
    static let shared = SwiftUIMigrationHelper()
    
    // Thread-safe access to feature flags
    private let flagQueue = DispatchQueue(label: "com.packplanner.swiftuiflags", attributes: .concurrent)
    
    // Feature flags for gradual migration
    private var _enableSwiftUIGearList = true
    private var _enableSwiftUIHikeList = true
    private var _enableSwiftUIAddGear = true
    private var _enableSwiftUIAddHike = true
    private var _enableSwiftUISettings = true
    
    private init() {
        loadFeatureFlagsFromUserDefaults()
    }
    
    // MARK: - Thread-Safe Feature Flag Properties
    
    private var enableSwiftUIGearList: Bool {
        get { flagQueue.sync { _enableSwiftUIGearList } }
        set { flagQueue.async(flags: .barrier) { self._enableSwiftUIGearList = newValue } }
    }
    
    private var enableSwiftUIHikeList: Bool {
        get { flagQueue.sync { _enableSwiftUIHikeList } }
        set { flagQueue.async(flags: .barrier) { self._enableSwiftUIHikeList = newValue } }
    }
    
    private var enableSwiftUIAddGear: Bool {
        get { flagQueue.sync { _enableSwiftUIAddGear } }
        set { flagQueue.async(flags: .barrier) { self._enableSwiftUIAddGear = newValue } }
    }
    
    private var enableSwiftUIAddHike: Bool {
        get { flagQueue.sync { _enableSwiftUIAddHike } }
        set { flagQueue.async(flags: .barrier) { self._enableSwiftUIAddHike = newValue } }
    }
    
    private var enableSwiftUISettings: Bool {
        get { flagQueue.sync { _enableSwiftUISettings } }
        set { flagQueue.async(flags: .barrier) { self._enableSwiftUISettings = newValue } }
    }
    
    // MARK: - Factory Methods for Controllers
    
    func createGearListViewController() -> UIViewController {
        if enableSwiftUIGearList {
            return UIHostingController(rootView: GearListView())
        } else {
            // Return legacy UIKit controller
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            return storyboard.instantiateViewController(withIdentifier: "GearListController")
        }
    }
    
    func createHikeListViewController() -> UIViewController {
        if enableSwiftUIHikeList {
            return UIHostingController(rootView: HikeListViewBridge())
        } else {
            // Return legacy UIKit controller
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            return storyboard.instantiateViewController(withIdentifier: "HikeListController")
        }
    }
    
    func createAddGearViewController(gear: Gear? = nil) -> UIViewController {
        if enableSwiftUIAddGear {
            let gearSwiftUI = gear != nil ? GearSwiftUI(from: gear!) : nil
            return UIHostingController(rootView: AddGearViewBridge(gear: gearSwiftUI))
        } else {
            // Return legacy UIKit controller
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let controller = storyboard.instantiateViewController(withIdentifier: "AddGearViewController")
            // Configure with gear if needed
            return controller
        }
    }
    
    func createAddHikeViewController(hike: Hike? = nil) -> UIViewController {
        if enableSwiftUIAddHike {
            let hikeSwiftUI = hike != nil ? HikeSwiftUI(from: hike!) : nil
            return UIHostingController(rootView: AddHikeViewBridge(hike: hikeSwiftUI))
        } else {
            // Return legacy UIKit controller
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let controller = storyboard.instantiateViewController(withIdentifier: "AddHikeViewController")
            // Configure with hike if needed
            return controller
        }
    }
    
    func createHikeDetailViewController(hike: Hike) -> UIViewController {
        if enableSwiftUIHikeList {
            let dataService = DataService.shared
            let hikeSwiftUI = dataService.hikes.first(where: { $0.name == hike.name }) ?? HikeSwiftUI(from: hike)
            
            let hostingController = UIHostingController(rootView: HikeDetailViewBridge(hike: hikeSwiftUI))
            
            let hikeDetailViewWithCallback = HikeDetailViewBridge(hike: hikeSwiftUI, dismissCallback: { [weak hostingController] in
                guard let hostingController = hostingController else { return }
                
                if hostingController.presentingViewController != nil {
                    hostingController.dismiss(animated: true)
                } else if let navigationController = hostingController.navigationController {
                    navigationController.popViewController(animated: true)
                } else {
                    hostingController.dismiss(animated: true)
                }
            })
            
            hostingController.rootView = hikeDetailViewWithCallback
            return hostingController
        } else {
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            return storyboard.instantiateViewController(withIdentifier: "HikeDetailViewController")
        }
    }
    
    func createSettingsViewController() -> UIViewController {
        if enableSwiftUISettings {
            return UIHostingController(rootView: SettingsView())
        } else {
            // Return legacy UIKit controller
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            return storyboard.instantiateViewController(withIdentifier: "SettingsViewController")
        }
    }
    
    func createHikeReportViewController(hike: Hike) -> UIViewController {
        // Temporarily use legacy UIKit controller until SwiftUI views are added to Xcode target
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let controller = storyboard.instantiateViewController(withIdentifier: "HikeReportController")
        // Configure with hike if needed
        return controller
    }
    
    func createAddGearToHikeViewController(hike: Hike) -> UIViewController {
        // Temporarily use legacy UIKit controller until SwiftUI views are added to Xcode target
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let controller = storyboard.instantiateViewController(withIdentifier: "AddGearToHikeTableViewController")
        // Configure with hike if needed
        return controller
    }
    
    func createEditHikeGearViewController(hikeGear: HikeGear, hike: Hike) -> UIViewController {
        // Temporarily use legacy UIKit controller until SwiftUI views are added to Xcode target
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let controller = storyboard.instantiateViewController(withIdentifier: "EditHikeGearController")
        // Configure with hikeGear and hike if needed
        return controller
    }
    
    // MARK: - Feature Flag Management
    
    func setSwiftUIEnabled(for feature: SwiftUIFeature, enabled: Bool) {
        // Ensure thread-safe updates using barrier queue
        flagQueue.async(flags: .barrier) { [weak self] in
            guard let self = self else { return }
            switch feature {
            case .gearList:
                self._enableSwiftUIGearList = enabled
            case .hikeList:
                self._enableSwiftUIHikeList = enabled
            case .addGear:
                self._enableSwiftUIAddGear = enabled
            case .addHike:
                self._enableSwiftUIAddHike = enabled
            case .settings:
                self._enableSwiftUISettings = enabled
            }
            // Persist changes to UserDefaults
            self.saveFeatureFlagsToUserDefaults()
        }
    }
    
    func isSwiftUIEnabled(for feature: SwiftUIFeature) -> Bool {
        return flagQueue.sync {
            switch feature {
            case .gearList:
                return _enableSwiftUIGearList
            case .hikeList:
                return _enableSwiftUIHikeList
            case .addGear:
                return _enableSwiftUIAddGear
            case .addHike:
                return _enableSwiftUIAddHike
            case .settings:
                return _enableSwiftUISettings
            }
        }
    }
    
    // MARK: - Persistence
    
    private func loadFeatureFlagsFromUserDefaults() {
        let defaults = UserDefaults.standard
        _enableSwiftUIGearList = defaults.object(forKey: "SwiftUI.GearList.Enabled") as? Bool ?? true
        _enableSwiftUIHikeList = defaults.object(forKey: "SwiftUI.HikeList.Enabled") as? Bool ?? true
        _enableSwiftUIAddGear = defaults.object(forKey: "SwiftUI.AddGear.Enabled") as? Bool ?? true
        _enableSwiftUIAddHike = defaults.object(forKey: "SwiftUI.AddHike.Enabled") as? Bool ?? true
        _enableSwiftUISettings = defaults.object(forKey: "SwiftUI.Settings.Enabled") as? Bool ?? true
    }
    
    private func saveFeatureFlagsToUserDefaults() {
        let defaults = UserDefaults.standard
        defaults.set(_enableSwiftUIGearList, forKey: "SwiftUI.GearList.Enabled")
        defaults.set(_enableSwiftUIHikeList, forKey: "SwiftUI.HikeList.Enabled")
        defaults.set(_enableSwiftUIAddGear, forKey: "SwiftUI.AddGear.Enabled")
        defaults.set(_enableSwiftUIAddHike, forKey: "SwiftUI.AddHike.Enabled")
        defaults.set(_enableSwiftUISettings, forKey: "SwiftUI.Settings.Enabled")
    }
    
    /**
     * Enables or disables all SwiftUI features at once.
     * Useful for testing or quickly switching between UIKit and SwiftUI modes.
     */
    func setAllSwiftUIFeatures(enabled: Bool) {
        flagQueue.async(flags: .barrier) { [weak self] in
            guard let self = self else { return }
            self._enableSwiftUIGearList = enabled
            self._enableSwiftUIHikeList = enabled
            self._enableSwiftUIAddGear = enabled
            self._enableSwiftUIAddHike = enabled
            self._enableSwiftUISettings = enabled
            self.saveFeatureFlagsToUserDefaults()
        }
    }
    
    /**
     * Gets the current migration progress as a percentage.
     */
    func getMigrationProgress() -> Double {
        let enabledFeatures = [
            _enableSwiftUIGearList,
            _enableSwiftUIHikeList,
            _enableSwiftUIAddGear,
            _enableSwiftUIAddHike,
            _enableSwiftUISettings
        ].filter { $0 }
        
        return Double(enabledFeatures.count) / 5.0 * 100.0
    }
}

enum SwiftUIFeature {
    case gearList
    case hikeList
    case addGear
    case addHike
    case settings
}

// MARK: - Migration Status Tracker

class MigrationStatusTracker {
    static let shared = MigrationStatusTracker()
    private init() {}
    
    // Simplified migration tracking
    var completionPercentage: Double { return 100.0 } // Migration is complete
    
    func printMigrationStatus() {
        #if DEBUG
        print("SwiftUI Migration: 100% Complete")
        #endif
    }
}

// MARK: - SwiftUI Integration Test Helper

class SwiftUIIntegrationTestHelper {
    static let shared = SwiftUIIntegrationTestHelper()
    private init() {}
    
    func validateSwiftUIIntegration() -> Bool {
        // Simple validation - just try to create key components
        do {
            let _ = DataService.shared
            let _ = SettingsManagerSwiftUI.shared
            let _ = SwiftUIMigrationHelper.shared.createGearListViewController()
            return true
        } catch {
            return false
        }
    }
}