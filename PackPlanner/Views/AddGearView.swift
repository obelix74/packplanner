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
                    TextField("Weight (grams)", text: $weight)
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
            weight = String(gear.weightInGrams)
            category = gear.category
        }
    }
    
    private func saveGear() {
        guard let weightValue = Double(weight) else {
            print("Invalid weight value: \(weight)")
            return
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
                print("Error fetching existing gear: \(error)")
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
        gearEntity.weightInGrams = weightValue
        gearEntity.category = category

        // Save to Core Data
        do {
            try context.save()
            print("✅ Gear saved to Core Data successfully")

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
            print("❌ Error saving gear to Core Data: \(error)")
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