//
//  AddHikeView.swift
//  PackPlanner
//
//  Created by Claude on SwiftUI Migration
//

import SwiftUI

struct AddHikeViewBridge: View {
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
    
    @Environment(\.dismiss) private var dismiss
    
    private var isEditing: Bool {
        hike != nil
    }
    
    private var isFormValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Hike Information") {
                    TextField("Hike Name", text: $name)
                    
                    TextField("Description (Optional)", text: $description)
                    
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
            .navigationBarItems(
                leading: Button("Cancel") {
                    // Notify parent controller that hike was cancelled
                    NotificationCenter.default.post(name: NSNotification.Name("HikeCancelled"), object: nil)
                    
                    if let hostingController = findHostingController() {
                        hostingController.dismiss(animated: true)
                    } else {
                        dismiss()
                    }
                }
                .foregroundColor(.blue),
                trailing: Button("Save") {
                    saveHike()
                }
                .foregroundColor(.blue)
                .font(.body.weight(.semibold))
                .disabled(!isFormValid)
            )
        }
        .onAppear {
            setupForm()
        }
    }
    
    private func setupForm() {
        if let hike = hike {
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
            
            dataService.updateHike(existingHike)
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
        
        // Notify parent controller that hike was saved
        NotificationCenter.default.post(name: NSNotification.Name("HikeSaved"), object: nil)
        
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