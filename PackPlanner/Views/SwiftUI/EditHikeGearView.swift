//
//  EditHikeGearView.swift
//  PackPlanner
//
//  Created by Claude on SwiftUI Migration
//

import SwiftUI

struct EditHikeGearView: View {
    @Binding var hikeGear: HikeGearSwiftUI
    let hike: HikeSwiftUI
    @State private var numberUnits: String = ""
    @State private var notes: String = ""
    @State private var consumable: Bool = false
    @State private var worn: Bool = false
    @State private var verified: Bool = false
    @Environment(\.dismiss) private var dismiss
    
    private var dataService = DataService.shared
    
    var body: some View {
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
                            .fontWeight(.semibold)
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
                    .foregroundColor(.white)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveChanges()
                    }
                    .foregroundColor(.white)
                    .fontWeight(.semibold)
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
        
        if settings.useImperialUnits {
            let ounces = weightInGrams * 0.035274
            return String(format: "%.2f oz", ounces)
        } else {
            return String(format: "%.1f g", weightInGrams)
        }
    }
}

struct EditHikeGearView_Previews: PreviewProvider {
    static var previews: some View {
        let sampleGear = GearSwiftUI()
        sampleGear.name = "Sample Gear"
        sampleGear.desc = "Sample description"
        sampleGear.weightInGrams = 100
        sampleGear.category = "Clothing"
        
        let sampleHikeGear = HikeGearSwiftUI()
        sampleHikeGear.gear = sampleGear
        sampleHikeGear.numberUnits = 1
        sampleHikeGear.consumable = false
        sampleHikeGear.worn = false
        sampleHikeGear.verified = false
        sampleHikeGear.notes = ""
        
        let sampleHike = HikeSwiftUI()
        sampleHike.name = "Sample Hike"
        
        return EditHikeGearView(hikeGear: .constant(sampleHikeGear), hike: sampleHike)
    }
}