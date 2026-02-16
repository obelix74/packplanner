//
//  SwiftUIBridge.swift
//  PackPlanner
//
//  Created by Claude on SwiftUI Migration
//

import Foundation
import SwiftUI
import UIKit
import CoreData
import os

// Import SwiftUI views from SwiftUI folder
// Note: These views are located in Views/SwiftUI/ folder

// MARK: - Embedded SwiftUI Views (temporary until Xcode target is updated)

public struct HikeDetailViewBridge: View {
    @ObservedObject var hike: HikeSwiftUI
    @ObservedObject private var settingsManager = SettingsManagerSwiftUI.shared
    @State private var showingAddGear = false
    @State private var showPendingOnly = false
    @State private var refreshTrigger = false
    @Environment(\.dismiss) private var dismiss
    private let context = CoreDataStack.shared.viewContext
    let dismissCallback: (() -> Void)?

    init(hike: HikeSwiftUI, dismissCallback: (() -> Void)? = nil) {
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
            // Save to Core Data
            saveHikeToCoreData()
            refreshHikeData()
        }
    }
    
    private func refreshHikeData() {
        // Reload from Core Data
        let fetchRequest: NSFetchRequest<HikeEntity> = HikeEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "uuid == %@", hike.id)

        do {
            let results = try context.fetch(fetchRequest)
            if let hikeEntity = results.first {
                let updatedHike = HikeSwiftUI(fromCoreData: hikeEntity)
                self.hike.hikeGears = updatedHike.hikeGears
            }
        } catch {
            Logger.coreData.error("Error refreshing hike data: \(error)")
        }
    }

    private func saveHikeToCoreData() {
        let fetchRequest: NSFetchRequest<HikeEntity> = HikeEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "uuid == %@", hike.id)

        do {
            let results = try context.fetch(fetchRequest)
            if let hikeEntity = results.first {
                // Update hike gear relationships
                // Remove all existing relationships
                if let existingGears = hikeEntity.hikeGears as? Set<HikeGearEntity> {
                    for gear in existingGears {
                        context.delete(gear)
                    }
                }

                // Add new relationships
                for hikeGearSwiftUI in hike.hikeGears {
                    let hikeGearEntity = HikeGearEntity(context: context)
                    hikeGearEntity.consumable = hikeGearSwiftUI.consumable
                    hikeGearEntity.numberUnits = Int32(hikeGearSwiftUI.numberUnits)
                    hikeGearEntity.notes = hikeGearSwiftUI.notes
                    hikeGearEntity.verified = hikeGearSwiftUI.verified
                    hikeGearEntity.worn = hikeGearSwiftUI.worn
                    hikeGearEntity.hike = hikeEntity

                    // Find the gear entity
                    if let gearSwiftUI = hikeGearSwiftUI.gear {
                        let gearFetch: NSFetchRequest<GearEntity> = GearEntity.fetchRequest()
                        gearFetch.predicate = NSPredicate(format: "uuid == %@", gearSwiftUI.id)
                        if let gearEntity = try? context.fetch(gearFetch).first {
                            hikeGearEntity.gear = gearEntity
                        }
                    }
                }

                try context.save()
            }
        } catch {
            Logger.coreData.error("Error saving hike to Core Data: \(error)")
        }
    }

}

public struct HikeHeaderViewBridge: View {
    let hike: HikeSwiftUI
    let refreshTrigger: Bool
    @ObservedObject private var settingsManager = SettingsManagerSwiftUI.shared
    
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
    @ObservedObject private var settingsManager = SettingsManagerSwiftUI.shared
    
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
    @ObservedObject private var settingsManager = SettingsManagerSwiftUI.shared
    private let context = CoreDataStack.shared.viewContext
    
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
                        saveHikeGearToCoreData()
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
                        saveHikeGearToCoreData()
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
                        saveHikeGearToCoreData()
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

    private func saveHikeGearToCoreData() {
        let fetchRequest: NSFetchRequest<HikeEntity> = HikeEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "uuid == %@", hike.id)

        do {
            let results = try context.fetch(fetchRequest)
            if let hikeEntity = results.first {
                // Find the specific HikeGearEntity to update
                if let hikeGearSet = hikeEntity.hikeGears as? Set<HikeGearEntity> {
                    for hikeGearEntity in hikeGearSet {
                        if let gearEntity = hikeGearEntity.gear, gearEntity.uuid == hikeGear.gear?.id {
                            // Update the properties
                            hikeGearEntity.worn = hikeGear.worn
                            hikeGearEntity.consumable = hikeGear.consumable
                            hikeGearEntity.verified = hikeGear.verified
                            break
                        }
                    }
                }
                try context.save()
            }
        } catch {
            Logger.coreData.error("Error saving hike gear to Core Data: \(error)")
        }
    }
}


public struct HikeListViewBridge: View {
    @ObservedObject private var settingsManager = SettingsManagerSwiftUI.shared
    @State private var searchText = ""
    @State private var showingAddHike = false
    @State private var selectedHike: HikeSwiftUI?
    @State private var showingHikeDetail = false
    @State private var hikes: [HikeSwiftUI] = []
    private let context = CoreDataStack.shared.viewContext

    private var filteredHikes: [HikeSwiftUI] {
        if searchText.isEmpty {
            return hikes
        } else {
            return hikes.filter { hike in
                hike.name.localizedCaseInsensitiveContains(searchText) ||
                hike.desc.localizedCaseInsensitiveContains(searchText) ||
                hike.location.localizedCaseInsensitiveContains(searchText)
            }
        }
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
                                        deleteHike(hike)
                                    }

                                    Button("Copy") {
                                        copyHike(hike)
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
                AddHikeView(hike: selectedHike)
                    .onDisappear {
                        loadHikesFromCoreData()
                    }
            }
            .sheet(isPresented: $showingHikeDetail) {
                if let hike = selectedHike {
                    Text("Hike Detail: \(hike.name)")
                }
            }
            .onAppear {
                loadHikesFromCoreData()
            }
            .refreshable {
                loadHikesFromCoreData()
            }
        }
    }

    private func loadHikesFromCoreData() {
        let fetchRequest: NSFetchRequest<HikeEntity> = HikeEntity.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]

        do {
            let results = try context.fetch(fetchRequest)
            hikes = results.map { HikeSwiftUI(fromCoreData: $0) }
        } catch {
            Logger.coreData.error("Error loading hikes: \(error)")
        }
    }

    private func deleteHike(_ hike: HikeSwiftUI) {
        let fetchRequest: NSFetchRequest<HikeEntity> = HikeEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "uuid == %@", hike.id)

        do {
            let results = try context.fetch(fetchRequest)
            if let hikeEntity = results.first {
                context.delete(hikeEntity)
                try context.save()
                loadHikesFromCoreData()
            }
        } catch {
            Logger.coreData.error("Error deleting hike: \(error)")
        }
    }

    private func copyHike(_ hike: HikeSwiftUI) {
        let hikeEntity = HikeEntity(context: context)
        hikeEntity.uuid = UUID().uuidString
        hikeEntity.name = "\(hike.name) (Copy)"
        hikeEntity.desc = hike.desc
        hikeEntity.distance = hike.distance
        hikeEntity.location = hike.location
        hikeEntity.completed = false
        hikeEntity.externalLink1 = hike.externalLink1
        hikeEntity.externalLink2 = hike.externalLink2
        hikeEntity.externalLink3 = hike.externalLink3

        // Copy hike gear relationships
        for hikeGearSwiftUI in hike.hikeGears {
            let hikeGearEntity = HikeGearEntity(context: context)
            hikeGearEntity.consumable = hikeGearSwiftUI.consumable
            hikeGearEntity.numberUnits = Int32(hikeGearSwiftUI.numberUnits)
            hikeGearEntity.notes = hikeGearSwiftUI.notes
            hikeGearEntity.verified = hikeGearSwiftUI.verified
            hikeGearEntity.worn = hikeGearSwiftUI.worn
            hikeGearEntity.hike = hikeEntity

            // Find the gear entity
            if let gearSwiftUI = hikeGearSwiftUI.gear {
                let gearFetch: NSFetchRequest<GearEntity> = GearEntity.fetchRequest()
                gearFetch.predicate = NSPredicate(format: "uuid == %@", gearSwiftUI.id)
                if let gearEntity = try? context.fetch(gearFetch).first {
                    hikeGearEntity.gear = gearEntity
                }
            }
        }

        do {
            try context.save()
            loadHikesFromCoreData()
        } catch {
            Logger.coreData.error("Error copying hike: \(error)")
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
    
    // Removed - use createAddGearViewControllerFromCoreData instead

    // Core Data version - using explicit method name to avoid ambiguity
    func createAddGearViewControllerFromCoreData(gear: GearEntity? = nil) -> UIViewController {
        if enableSwiftUIAddGear {
            let gearSwiftUI = gear != nil ? GearSwiftUI(fromCoreData: gear!) : nil
            return UIHostingController(rootView: AddGearViewBridge(gear: gearSwiftUI))
        } else {
            // Return legacy UIKit controller
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let controller = storyboard.instantiateViewController(withIdentifier: "AddGearViewController") as! AddGearViewController
            controller.existingGearCoreData = gear
            return controller
        }
    }
    
    // Removed - use Core Data version instead
    func createAddHikeViewController(hikeCoreData: HikeEntity? = nil) -> UIViewController {
        if enableSwiftUIAddHike {
            let hikeSwiftUI = hikeCoreData != nil ? HikeSwiftUI(fromCoreData: hikeCoreData!) : nil
            return UIHostingController(rootView: AddHikeView(hike: hikeSwiftUI))
        } else {
            // Return legacy UIKit controller
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let controller = storyboard.instantiateViewController(withIdentifier: "AddHikeViewController")
            // Configure with hike if needed
            return controller
        }
    }
    
    // Removed - use Core Data version only

    // Core Data version
    func createHikeDetailViewController(hikeCoreData: HikeEntity) -> UIViewController {
        if enableSwiftUIHikeList {
            let hikeSwiftUI = HikeSwiftUI(fromCoreData: hikeCoreData)

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
            let controller = storyboard.instantiateViewController(withIdentifier: "HikeDetailViewController") as! HikeDetailViewController
            controller.hikeEntity = hikeCoreData
            return controller
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
    
    // Removed legacy Realm methods - use Core Data equivalents
    func createHikeReportViewController(hikeCoreData: HikeEntity) -> UIViewController {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let controller = storyboard.instantiateViewController(withIdentifier: "HikeReportController")
        return controller
    }

    func createAddGearToHikeViewController(hikeCoreData: HikeEntity) -> UIViewController {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let controller = storyboard.instantiateViewController(withIdentifier: "AddGearToHikeTableViewController")
        return controller
    }

    func createEditHikeGearViewController(hikeGearCoreData: HikeGearEntity, hikeCoreData: HikeEntity) -> UIViewController {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let controller = storyboard.instantiateViewController(withIdentifier: "EditHikeGearController")
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

