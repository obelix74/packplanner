//
//  AddHikeView.swift
//  PackPlanner
//
//  Created by Claude on SwiftUI Migration
//

import SwiftUI

struct AddHikeView: View {
    let hike: HikeSwiftUI?
    
    @State private var dataService = DataService.shared
    @State private var name = ""
    @State private var description = ""
    @State private var location = ""
    @State private var distance = ""
    @State private var completed = false
    @State private var externalLink1 = ""
    @State private var externalLink2 = ""
    @State private var externalLink3 = ""
    @State private var originalName = "" // Store original name for updates
    
    @Environment(\.dismiss) private var dismiss
    
    private var isEditing: Bool {
        hike != nil
    }
    
    private var isFormValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var body: some View {
        Form {
                Section("Hike Information") {
                    TextField("Hike Name", text: $name)
                    
                    TextField("Description (Optional)", text: $description)
                        .lineLimit(3)
                    
                    TextField("Location (Optional)", text: $location)
                    
                    TextField("Distance (Optional)", text: $distance)
                }
                
                Section("Status") {
                    Toggle("Completed", isOn: $completed)
                }
                
                Section("External Links") {
                    TextField("Link 1 (Optional)", text: $externalLink1)
                        .keyboardType(.URL)
                        .autocapitalization(.none)
                    
                    TextField("Link 2 (Optional)", text: $externalLink2)
                        .keyboardType(.URL)
                        .autocapitalization(.none)
                    
                    TextField("Link 3 (Optional)", text: $externalLink3)
                        .keyboardType(.URL)
                        .autocapitalization(.none)
                }
            }
        .navigationTitle(isEditing ? "Edit Hike" : "Add Hike")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(content: {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") {
                    NotificationCenter.default.post(name: NSNotification.Name("HikeCancelled"), object: nil)
                    dismiss()
                }
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Save") {
                    saveHike()
                }
                .disabled(!isFormValid)
            }
        })
        .onAppear {
            setupForm()
        }
    }
    
    private func setupForm() {
        if let hike = hike {
            originalName = hike.name // Store original name
            name = hike.name
            description = hike.desc
            location = hike.location
            distance = hike.distance
            completed = hike.completed
            externalLink1 = hike.externalLink1
            externalLink2 = hike.externalLink2
            externalLink3 = hike.externalLink3
        }
    }
    
    private func saveHike() {
        if let existingHike = hike {
            existingHike.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
            existingHike.desc = description.trimmingCharacters(in: .whitespacesAndNewlines)
            existingHike.location = location.trimmingCharacters(in: .whitespacesAndNewlines)
            existingHike.distance = distance.trimmingCharacters(in: .whitespacesAndNewlines)
            existingHike.completed = completed
            existingHike.externalLink1 = externalLink1.trimmingCharacters(in: .whitespacesAndNewlines)
            existingHike.externalLink2 = externalLink2.trimmingCharacters(in: .whitespacesAndNewlines)
            existingHike.externalLink3 = externalLink3.trimmingCharacters(in: .whitespacesAndNewlines)
            
            dataService.updateHike(existingHike, originalName: originalName)
        } else {
            let newHike = HikeSwiftUI(
                name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                desc: description.trimmingCharacters(in: .whitespacesAndNewlines),
                distance: distance.trimmingCharacters(in: .whitespacesAndNewlines),
                location: location.trimmingCharacters(in: .whitespacesAndNewlines)
            )
            
            newHike.completed = completed
            newHike.externalLink1 = externalLink1.trimmingCharacters(in: .whitespacesAndNewlines)
            newHike.externalLink2 = externalLink2.trimmingCharacters(in: .whitespacesAndNewlines)
            newHike.externalLink3 = externalLink3.trimmingCharacters(in: .whitespacesAndNewlines)
            
            dataService.addHike(newHike)
        }
        
        // Notify UIKit that hike was saved
        NotificationCenter.default.post(name: NSNotification.Name("HikeSaved"), object: nil)
        dismiss()
    }
}

#Preview {
    AddHikeView(hike: nil)
}