//
//  HikeReportView.swift
//  PackPlanner
//
//  Created by Claude on SwiftUI Migration
//

import SwiftUI

struct HikeReportView: View {
    let hike: HikeSwiftUI
    @State private var selectedFilter = "Total weight"
    @State private var reportData: [String: Double] = [:]
    @State private var sortedKeys: [String] = []
    @Environment(\.dismiss) private var dismiss
    
    private let filters = ["Total weight", "Base weight", "Consumable weight", "Worn weight"]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Title and Summary
                VStack(spacing: 10) {
                    Text("Weight Report")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text(formatWeight(totalWeight))
                        .font(.title)
                        .fontWeight(.heavy)
                        .foregroundColor(.red)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                // Filter Picker
                VStack(alignment: .leading, spacing: 8) {
                    Text("Filter by:")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Picker("Weight Filter", selection: $selectedFilter) {
                        ForEach(filters, id: \.self) { filter in
                            Text(filter).tag(filter)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                .padding(.horizontal)
                
                // Report Table
                List {
                    ForEach(sortedKeys, id: \.self) { key in
                        HStack {
                            Text(key)
                                .font(.body)
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            Text(formatWeight(reportData[key] ?? 0))
                                .font(.body)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }
                .listStyle(PlainListStyle())
                
                Spacer()
            }
            .padding()
            .navigationTitle("Report: \(hike.name)")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Dismiss") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
            .background(Color(.systemBackground))
        }
        .onAppear {
            updateReportData()
        }
        .onChange(of: selectedFilter) { _ in
            updateReportData()
        }
    }
    
    private var totalWeight: Double {
        return calculateTotalWeight()
    }
    
    private func updateReportData() {
        let hikeBrain = HikeBrain(hike: hike.toLegacyHike())
        var newReportData: [String: Double] = [:]
        
        switch selectedFilter {
        case "Total weight":
            newReportData = hikeBrain.getTotalWeightByCategoryInGrams()
        case "Base weight":
            newReportData = hikeBrain.getBaseWeightByCategoryInGrams()
        case "Consumable weight":
            newReportData = hikeBrain.getConsumableWeightByCategoryInGrams()
        case "Worn weight":
            newReportData = hikeBrain.getWornWeightByCategoryInGrams()
        default:
            newReportData = hikeBrain.getTotalWeightByCategoryInGrams()
        }
        
        reportData = newReportData
        sortedKeys = newReportData.keys.sorted()
    }
    
    private func calculateTotalWeight() -> Double {
        let hikeBrain = HikeBrain(hike: hike.toLegacyHike())
        
        switch selectedFilter {
        case "Total weight":
            return hikeBrain.getTotalWeightInGrams()
        case "Base weight":
            return hikeBrain.getBaseWeightInGrams()
        case "Consumable weight":
            return hikeBrain.getConsumableWeightInGrams()
        case "Worn weight":
            return hikeBrain.getWornWeightInGrams()
        default:
            return hikeBrain.getTotalWeightInGrams()
        }
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

struct HikeReportView_Previews: PreviewProvider {
    static var previews: some View {
        let sampleHike = HikeSwiftUI()
        sampleHike.name = "Sample Hike"
        sampleHike.desc = "A sample hike for preview"
        sampleHike.location = "Sample Location"
        sampleHike.distance = 10.5
        
        return HikeReportView(hike: sampleHike)
    }
}