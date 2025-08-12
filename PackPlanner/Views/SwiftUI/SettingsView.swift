//
//  SettingsView.swift
//  PackPlanner
//
//  Created by Claude on SwiftUI Migration
//

import SwiftUI

struct SettingsView: View {
    @State private var settingsManager = SettingsManagerSwiftUI.shared
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section("Units") {
                    Picker("Weight Unit", selection: $settingsManager.isImperial) {
                        Text("Metric (kg/g)").tag(false)
                        Text("Imperial (lbs/oz)").tag(true)
                    }
                    .pickerStyle(.segmented)
                }
                
                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("SwiftUI Mode")
                        Spacer()
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    }
                }
                
                Section("Support") {
                    Link("Rate PackPlanner", destination: URL(string: "https://apps.apple.com")!)
                    Link("Contact Support", destination: URL(string: "mailto:support@packplanner.app")!)
                    Link("Privacy Policy", destination: URL(string: "https://packplanner.app/privacy")!)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    SettingsView()
}