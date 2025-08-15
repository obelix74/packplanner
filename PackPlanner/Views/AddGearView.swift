//
//  AddGearView.swift
//  PackPlanner
//
//  Created by Claude on SwiftUI Migration
//

import SwiftUI

struct AddGearViewBridge: View {
    let gear: GearSwiftUI?
    @State private var name = ""
    @State private var description = ""
    @State private var weight = ""
    @State private var category = "Clothing"
    @Environment(\.dismiss) private var dismiss
    
    private let categories = ["Clothing", "Cooking", "Electronics", "Navigation", "Safety", "Shelter", "Water & Hydration", "Other"]
    private var dataService = DataService.shared
    
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
        
        if let existingGear = gear {
            // Update existing gear
            existingGear.name = name
            existingGear.desc = description
            existingGear.weightInGrams = weightValue
            existingGear.category = category
            dataService.updateGear(existingGear)
        } else {
            // Create new gear
            let newGear = GearSwiftUI()
            newGear.name = name
            newGear.desc = description
            newGear.weightInGrams = weightValue
            newGear.category = category
            dataService.addGear(newGear)
        }
        
        // Notify parent controller that gear was saved
        NotificationCenter.default.post(name: NSNotification.Name("GearSaved"), object: nil)
        
        // For UIKit presentation, we need to dismiss the hosting controller
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            if let hostingController = findHostingController() {
                hostingController.dismiss(animated: true)
            } else {
                // Fallback to SwiftUI dismiss if in sheet context
                dismiss()
            }
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