//
//  AddGearView.swift
//  PackPlanner
//
//  Created by Claude on SwiftUI Migration
//

import SwiftUI
import CoreData

struct AddGearViewBridge: View {
    let gear: GearSwiftUI?
    @State private var name = ""
    @State private var description = ""
    @State private var weight = ""
    @State private var category = "Backpack"
    @Environment(\.dismiss) private var dismiss
    @StateObject private var settingsManager = SettingsManagerSwiftUI.shared

    private let categories = Categories.SINGLETON.list
    private let context = CoreDataStack.shared.viewContext

    init(gear: GearSwiftUI? = nil) {
        self.gear = gear
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Gear Details")) {
                    TextField("Name", text: $name)
                    TextField("Description", text: $description)
                    TextField("Weight (\(settingsManager.isImperial ? "oz" : "g"))", text: $weight)
                        .keyboardType(.decimalPad)
                }
                
                Section(header: Text("Category")) {
                    Picker("Category", selection: $category) {
                        ForEach(categories, id: \.self) { category in
                            Text(category).tag(category)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                }
            }
            .navigationTitle(gear == nil ? "Add Gear" : "Edit Gear")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Cancel") {
                    // Notify parent controller that gear was cancelled
                    NotificationCenter.default.post(name: NSNotification.Name("GearCancelled"), object: nil)
                    
                    if let hostingController = findHostingController() {
                        hostingController.dismiss(animated: true)
                    } else {
                        dismiss()
                    }
                }
                .foregroundColor(.blue),
                trailing: Button("Save") {
                    saveGear()
                }
                .foregroundColor(.blue)
                .font(.body.weight(.semibold))
                .disabled(name.isEmpty || weight.isEmpty)
            )
        }
        .onAppear {
            loadGearData()
        }
    }
    
    private func loadGearData() {
        if let gear = gear {
            name = gear.name
            description = gear.desc

            // Convert weight based on settings
            if settingsManager.isImperial {
                let ounces = gear.weightInGrams * 0.035274
                weight = String(format: "%.2f", ounces)
            } else {
                weight = String(format: "%.1f", gear.weightInGrams)
            }

            category = gear.category
        }
    }
    
    private func saveGear() {
        guard let weightValue = Double(weight) else {
            return
        }

        // Convert weight to grams if in imperial
        let weightInGrams: Double
        if settingsManager.isImperial {
            // User entered ounces, convert to grams
            weightInGrams = weightValue / 0.035274
        } else {
            // Already in grams
            weightInGrams = weightValue
        }

        // Save to Core Data
        let gearEntity: GearEntity
        if let existingGear = gear {
            // Update existing gear - need to fetch from Core Data
            let fetchRequest: NSFetchRequest<GearEntity> = GearEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "uuid == %@", existingGear.id)

            do {
                let results = try context.fetch(fetchRequest)
                if let existing = results.first {
                    gearEntity = existing
                } else {
                    // If not found, create new
                    gearEntity = GearEntity(context: context)
                    gearEntity.uuid = UUID().uuidString
                }
            } catch {
                return
            }
        } else {
            // Create new gear
            gearEntity = GearEntity(context: context)
            gearEntity.uuid = UUID().uuidString
        }

        // Set values
        gearEntity.name = name
        gearEntity.desc = description
        gearEntity.weightInGrams = weightInGrams
        gearEntity.category = category

        // Save to Core Data
        do {
            try context.save()

            // Notify parent controller that gear was saved
            NotificationCenter.default.post(name: NSNotification.Name("GearSaved"), object: nil)

            // Dismiss after a short delay to allow notification to propagate
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                if let hostingController = findHostingController() {
                    hostingController.dismiss(animated: true)
                } else {
                    // Fallback to SwiftUI dismiss if in sheet context
                    dismiss()
                }
            }
        } catch {
            // Silently handle error
        }
    }
    
    private func findHostingController() -> UIViewController? {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            return nil
        }
        
        // Find the presented view controller (should be the navigation controller)
        var controller = window.rootViewController
        while let presented = controller?.presentedViewController {
            controller = presented
        }
        
        return controller
    }
}