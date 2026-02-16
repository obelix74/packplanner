//
//  HikeReportView.swift
//  PackPlanner
//
//  Created by Claude on SwiftUI Migration
//

import SwiftUI

struct HikeReportView: View {
    let hike: HikeSwiftUI
    @ObservedObject private var settingsManager = SettingsManagerSwiftUI.shared
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

                    Text(settingsManager.formatWeight(totalWeight))
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

                            Text(settingsManager.formatWeight(reportData[key] ?? 0))
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
        var data: [String: Double] = [:]
        let groupedGear = Dictionary(grouping: hike.hikeGears) { hikeGear in
            hikeGear.gear?.category ?? "Unknown"
        }

        for (category, gears) in groupedGear {
            let categoryWeight = gears.reduce(0.0) { total, hikeGear in
                guard let gear = hikeGear.gear else { return total }
                let unitWeight = gear.weightInGrams * Double(hikeGear.numberUnits)

                switch selectedFilter {
                case "Base weight":
                    return hikeGear.consumable || hikeGear.worn ? total : total + unitWeight
                case "Consumable weight":
                    return hikeGear.consumable ? total + unitWeight : total
                case "Worn weight":
                    return hikeGear.worn ? total + unitWeight : total
                default:
                    return total + unitWeight
                }
            }

            if categoryWeight > 0 {
                data[category] = categoryWeight
            }
        }

        reportData = data
        sortedKeys = data.keys.sorted { data[$0] ?? 0 > data[$1] ?? 0 }
    }

    private func calculateTotalWeight() -> Double {
        return hike.hikeGears.reduce(0) { total, hikeGear in
            guard let gear = hikeGear.gear else { return total }
            let unitWeight = gear.weightInGrams * Double(hikeGear.numberUnits)

            switch selectedFilter {
            case "Base weight":
                return hikeGear.consumable || hikeGear.worn ? total : total + unitWeight
            case "Consumable weight":
                return hikeGear.consumable ? total + unitWeight : total
            case "Worn weight":
                return hikeGear.worn ? total + unitWeight : total
            default:
                return total + unitWeight
            }
        }
    }
}

#Preview {
    let sampleHike = HikeSwiftUI()
    sampleHike.name = "Sample Hike"
    sampleHike.desc = "A sample hike for preview"
    sampleHike.location = "Sample Location"
    sampleHike.distance = "10.5"

    return HikeReportView(hike: sampleHike)
}
