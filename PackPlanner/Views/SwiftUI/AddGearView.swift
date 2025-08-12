//
//  AddGearView.swift
//  PackPlanner
//
//  Created by Claude on SwiftUI Migration
//

import SwiftUI

struct AddGearView: View {
    let gear: GearSwiftUI?
    
    @State private var dataService = DataService.shared
    @State private var settingsManager = SettingsManagerSwiftUI.shared
    @State private var categories = Categories.SINGLETON
    
    @State private var name = ""
    @State private var description = ""
    @State private var weight = ""
    @State private var selectedCategory = "Uncategorized"
    
    @Environment(\.dismiss) private var dismiss
    
    private var isEditing: Bool {
        gear != nil
    }
    
    private var isFormValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !weight.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        Double(weight) != nil
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Gear Information") {
                    TextField("Name", text: $name)
                    
                    TextField("Description (Optional)", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section("Weight") {
                    HStack {
                        TextField("Weight", text: $weight)
                            .keyboardType(.decimalPad)
                        
                        Text(settingsManager.weightUnit)
                            .foregroundColor(.secondary)
                    }
                }
                
                Section("Category") {
                    Picker("Category", selection: $selectedCategory) {
                        ForEach(categories.list, id: \.self) { category in
                            Text(category).tag(category)
                        }
                    }
                    .pickerStyle(.wheel)
                }
            }
            .navigationTitle(isEditing ? "Edit Gear" : "Add Gear")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveGear()
                    }
                    .disabled(!isFormValid)
                }
            }
        }
        .onAppear {
            setupForm()
        }
    }
    
    private func setupForm() {
        if let gear = gear {
            name = gear.name
            description = gear.desc
            weight = String(format: "%.1f", gear.weight(imperial: settingsManager.isImperial))
            selectedCategory = gear.category
        }
    }
    
    private func saveGear() {
        guard let weightValue = Double(weight) else { return }
        
        if let existingGear = gear {
            existingGear.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
            existingGear.desc = description.trimmingCharacters(in: .whitespacesAndNewlines)
            existingGear.setWeight(weight: weightValue, imperial: settingsManager.isImperial)
            existingGear.category = selectedCategory
            
            dataService.updateGear(existingGear)
        } else {
            let newGear = GearSwiftUI(
                name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                desc: description.trimmingCharacters(in: .whitespacesAndNewlines),
                weight: weightValue,
                category: selectedCategory,
                imperial: settingsManager.isImperial
            )
            
            dataService.addGear(newGear)
        }
        
        dismiss()
    }
}

#Preview {
    AddGearView(gear: nil)
}