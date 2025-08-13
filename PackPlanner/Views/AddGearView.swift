//
//  AddGearView.swift
//  PackPlanner
//
//  Created by Claude on SwiftUI Migration
//

import SwiftUI
import RealmSwift

struct AddGearView: View {
    @StateObject private var settingsManager = SettingsManagerSwiftUI.shared
    @Environment(\.dismiss) private var dismiss
    
    // Form data
    @State private var name: String = ""
    @State private var description: String = ""
    @State private var weightText: String = ""
    @State private var selectedCategory: String = "Uncategorized"
    
    // Validation
    @State private var showAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    
    // Categories
    private let categories = Categories.SINGLETON.list
    
    // Gear to edit (if any)
    let gear: GearSwiftUI?
    
    // Completion handler for UIKit integration
    let onSave: (() -> Void)?
    let onCancel: (() -> Void)?
    
    init(gear: GearSwiftUI? = nil, onSave: (() -> Void)? = nil, onCancel: (() -> Void)? = nil) {
        self.gear = gear
        self.onSave = onSave
        self.onCancel = onCancel
        if let existingGear = gear {
            _name = State(initialValue: existingGear.name)
            _description = State(initialValue: existingGear.desc)
            _selectedCategory = State(initialValue: existingGear.category)
            // Use a safe fallback since SettingsManagerSwiftUI might not be fully initialized yet
            let isImperialMode = SettingsManager.SINGLETON.settings.imperial
            let weight = isImperialMode ? 
                existingGear.weight(imperial: true) : 
                existingGear.weight(imperial: false)
            _weightText = State(initialValue: String(format: "%.2f", weight))
        }
    }
    
    private var weightUnit: String {
        settingsManager.isImperial ? "lbs/oz" : "kg/g"
    }
    
    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !weightText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        Double(weightText) != nil
    }
    
    var body: some View {
        Form {
                Section(header: Text("Gear Details")) {
                    HStack {
                        Image(systemName: "tag")
                            .foregroundColor(.blue)
                            .frame(width: 24)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Name")
                                .font(.headline)
                            TextField("Enter the name of this gear", text: $name)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                    }
                    .padding(.vertical, 4)
                    
                    HStack {
                        Image(systemName: "doc.text")
                            .foregroundColor(.green)
                            .frame(width: 24)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Description")
                                .font(.headline)
                            TextField("Enter the description of this gear", text: $description)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                    }
                    .padding(.vertical, 4)
                    
                    HStack {
                        Image(systemName: "scalemass")
                            .foregroundColor(.orange)
                            .frame(width: 24)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Weight (\(weightUnit))")
                                .font(.headline)
                            TextField("Enter the weight in \(weightUnit)", text: $weightText)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .keyboardType(.decimalPad)
                        }
                    }
                    .padding(.vertical, 4)
                }
                
                Section(header: Text("Category")) {
                    HStack {
                        Image(systemName: "folder")
                            .foregroundColor(.purple)
                            .frame(width: 24)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Category")
                                .font(.headline)
                            
                            Picker("Category", selection: $selectedCategory) {
                                ForEach(categories, id: \.self) { category in
                                    Text(category)
                                        .tag(category)
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                        }
                        
                        Spacer()
                    }
                    .padding(.vertical, 4)
                }
                
                if gear != nil {
                    Section(header: Text("Actions")) {
                        HStack {
                            Image(systemName: "info.circle")
                                .foregroundColor(.blue)
                                .frame(width: 24)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Editing Existing Gear")
                                    .font(.headline)
                                Text("Changes will update the existing gear item")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        .navigationTitle(gear != nil ? "Edit Gear" : "Add Gear")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(content: {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") {
                    NotificationCenter.default.post(name: NSNotification.Name("GearCancelled"), object: nil)
                    if let onCancel = onCancel {
                        onCancel()
                    } else {
                        dismiss()
                    }
                }
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Save") {
                    saveGear()
                }
                .disabled(!isValid)
            }
        })
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text(alertTitle),
                message: Text(alertMessage),
                dismissButton: .default(Text("OK"))
            )
        }
    }
    
    private func saveGear() {
        // Validate inputs
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedWeight = weightText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmedName.isEmpty {
            showValidationAlert(title: "Missing Input", message: "Name is required")
            return
        }
        
        guard let weightValue = Double(trimmedWeight) else {
            showValidationAlert(title: "Invalid Weight", message: "Please enter a valid weight")
            return
        }
        
        if weightValue <= 0 {
            showValidationAlert(title: "Invalid Weight", message: "Weight must be greater than zero")
            return
        }
        
        // Create or update gear
        do {
            let realm = try Realm()
            try realm.write {
                if let existingGear = gear {
                    // Find and update existing gear in Realm by uuid
                    if let realmGear = realm.objects(Gear.self).filter("uuid == %@", existingGear.id).first {
                        realmGear.setValues(
                            name: trimmedName,
                            desc: description.trimmingCharacters(in: .whitespacesAndNewlines),
                            weight: weightValue,
                            category: selectedCategory
                        )
                    }
                } else {
                    // Create new gear
                    let newGear = Gear()
                    newGear.setValues(
                        name: trimmedName,
                        desc: description.trimmingCharacters(in: .whitespacesAndNewlines),
                        weight: weightValue,
                        category: selectedCategory
                    )
                    realm.add(newGear)
                }
            }
            
            // Notify UIKit that gear was saved and dismiss
            NotificationCenter.default.post(name: NSNotification.Name("GearSaved"), object: nil)
            
            // Dismiss the view using completion handler or SwiftUI dismiss
            if let onSave = onSave {
                onSave()
            } else {
                dismiss()
            }
            
        } catch {
            showValidationAlert(title: "Save Error", message: "Failed to save gear: \(error.localizedDescription)")
        }
    }
    
    private func showValidationAlert(title: String, message: String) {
        alertTitle = title
        alertMessage = message
        showAlert = true
    }
}

#if DEBUG
struct AddGearView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            AddGearView()
                .previewDisplayName("Add New Gear")
            
            AddGearView(gear: {
                let gear = GearSwiftUI()
                gear.name = "Test Backpack"
                gear.desc = "A sample backpack for testing"
                gear.weightInGrams = 1500
                gear.category = "Backpack"
                return gear
            }())
            .previewDisplayName("Edit Existing Gear")
        }
    }
}
#endif