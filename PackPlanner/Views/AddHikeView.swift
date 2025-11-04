//
//  AddHikeView.swift
//  PackPlanner
//
//  Created by Claude on SwiftUI Migration
//

import SwiftUI
import CoreData

struct AddHikeViewBridge: View {
    let hike: HikeSwiftUI?

    @State private var name = ""
    @State private var description = ""
    @State private var location = ""
    @State private var distance = ""
    @State private var completed = false
    @State private var externalLink1 = ""
    @State private var externalLink2 = ""
    @State private var externalLink3 = ""

    @Environment(\.dismiss) private var dismiss
    private let context = CoreDataStack.shared.viewContext
    
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
        // Save to Core Data
        let hikeEntity: HikeEntity
        if let existingHike = hike {
            // Update existing hike - need to fetch from Core Data
            let fetchRequest: NSFetchRequest<HikeEntity> = HikeEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "name == %@", existingHike.name)

            do {
                let results = try context.fetch(fetchRequest)
                if let existing = results.first {
                    hikeEntity = existing
                } else {
                    // If not found, create new
                    hikeEntity = HikeEntity(context: context)
                }
            } catch {
                print("Error fetching existing hike: \(error)")
                return
            }
        } else {
            // Create new hike
            hikeEntity = HikeEntity(context: context)
        }

        // Set values
        hikeEntity.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        hikeEntity.desc = description.trimmingCharacters(in: .whitespacesAndNewlines)
        hikeEntity.location = location.trimmingCharacters(in: .whitespacesAndNewlines)
        hikeEntity.distance = distance.trimmingCharacters(in: .whitespacesAndNewlines)
        hikeEntity.completed = completed

        // Set external links (only if not empty)
        let link1 = externalLink1.trimmingCharacters(in: .whitespacesAndNewlines)
        let link2 = externalLink2.trimmingCharacters(in: .whitespacesAndNewlines)
        let link3 = externalLink3.trimmingCharacters(in: .whitespacesAndNewlines)

        hikeEntity.externalLink1 = link1.isEmpty ? nil : link1
        hikeEntity.externalLink2 = link2.isEmpty ? nil : link2
        hikeEntity.externalLink3 = link3.isEmpty ? nil : link3

        // Save to Core Data
        do {
            try context.save()
            print("✅ Hike saved to Core Data successfully")

            // Notify parent controller that hike was saved
            NotificationCenter.default.post(name: NSNotification.Name("HikeSaved"), object: nil)

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
            print("❌ Error saving hike to Core Data: \(error)")
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