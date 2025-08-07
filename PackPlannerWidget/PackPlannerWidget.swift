//
//  PackPlannerWidget.swift
//  PackPlannerWidget
//
//  Home screen widgets for PackPlanner
//

import WidgetKit
import SwiftUI
// import RealmSwift  // Temporarily disabled for build fix

struct PackPlannerWidget: Widget {
    let kind: String = "PackPlannerWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: HikeProvider()) { entry in
            if #available(iOS 17.0, *) {
                PackPlannerWidgetEntryView(entry: entry)
                    .containerBackground(.fill.tertiary, for: .widget)
            } else {
                PackPlannerWidgetEntryView(entry: entry)
                    .padding()
                    .background()
            }
        }
        .configurationDisplayName("Hike Summary")
        .description("View your upcoming hikes and gear weight.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

// MARK: - Widget Entry

struct HikeEntry: TimelineEntry {
    let date: Date
    let upcomingHikes: [HikeWidgetData]
    let totalGearCount: Int
    let averageWeight: String
}

struct HikeWidgetData: Identifiable {
    let id = UUID()
    let name: String
    let totalWeight: String
    let baseWeight: String
    let gearCount: Int
    let completed: Bool
    let hasGear: Bool
}

// MARK: - Timeline Provider

struct HikeProvider: TimelineProvider {
    func placeholder(in context: Context) -> HikeEntry {
        HikeEntry(
            date: Date(),
            upcomingHikes: [
                HikeWidgetData(
                    name: "Mount Whitney",
                    totalWeight: "32.5 lb",
                    baseWeight: "18.2 lb",
                    gearCount: 24,
                    completed: false,
                    hasGear: true
                )
            ],
            totalGearCount: 45,
            averageWeight: "28.3 lb"
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (HikeEntry) -> ()) {
        let entry = createEntry()
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        let entry = createEntry()
        
        // Update every hour
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date()
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        
        completion(timeline)
    }
    
    private func createEntry() -> HikeEntry {
        do {
            // Use app group to share Realm database with widget
            let appGroupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.com.packplanner.shared")
            let realmURL = appGroupURL?.appendingPathComponent("packplanner.realm")
            
            let config = Realm.Configuration(fileURL: realmURL)
            let realm = try Realm(configuration: config)
            
            let hikes = realm.objects(HikeSwiftUI.self).sorted(byKeyPath: "name", ascending: true)
            let gears = realm.objects(GearSwiftUI.self)
            
            let hikeData = Array(hikes.prefix(5)).map { hike in
                HikeWidgetData(
                    name: hike.name,
                    totalWeight: hike.totalWeightString,
                    baseWeight: hike.baseWeightString,
                    gearCount: hike.hikeGears.count,
                    completed: hike.completed,
                    hasGear: !hike.hikeGears.isEmpty
                )
            }
            
            let totalWeight = hikes.reduce(0.0) { $0 + $1.totalWeight }
            let averageWeight = hikes.count > 0 ? totalWeight / Double(hikes.count) : 0
            let averageWeightString = GearSwiftUI.getWeightString(weight: averageWeight)
            
            return HikeEntry(
                date: Date(),
                upcomingHikes: hikeData,
                totalGearCount: gears.count,
                averageWeight: averageWeightString
            )
        } catch {
            print("Widget error accessing Realm: \(error)")
            // Return placeholder data on error
            return HikeEntry(
                date: Date(),
                upcomingHikes: [],
                totalGearCount: 0,
                averageWeight: "0.0 lb"
            )
        }
    }
}

// MARK: - Widget Views

struct PackPlannerWidgetEntryView : View {
    var entry: HikeProvider.Entry
    @Environment(\.widgetFamily) var family
    
    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(entry: entry)
        case .systemMedium:
            MediumWidgetView(entry: entry)
        case .systemLarge:
            LargeWidgetView(entry: entry)
        default:
            SmallWidgetView(entry: entry)
        }
    }
}

struct SmallWidgetView: View {
    let entry: HikeEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: "mountain.2")
                    .foregroundColor(.accentColor)
                Text("PackPlanner")
                    .font(.caption)
                    .fontWeight(.medium)
                Spacer()
            }
            
            if let firstHike = entry.upcomingHikes.first {
                VStack(alignment: .leading, spacing: 2) {
                    Text(firstHike.name)
                        .font(.headline)
                        .lineLimit(2)
                    
                    Text(firstHike.totalWeight)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        Image(systemName: "backpack")
                            .font(.caption2)
                        Text("\(firstHike.gearCount)")
                            .font(.caption2)
                        
                        Spacer()
                        
                        if firstHike.completed {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                                .font(.caption2)
                        }
                    }
                    .foregroundColor(.secondary)
                }
            } else {
                VStack(alignment: .leading) {
                    Text("No hikes")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Text("Add your first hike")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
        }
        .padding()
    }
}

struct MediumWidgetView: View {
    let entry: HikeEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "mountain.2")
                    .foregroundColor(.accentColor)
                Text("Recent Hikes")
                    .font(.headline)
                    .fontWeight(.medium)
                Spacer()
                Text("\(entry.totalGearCount) gear")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if entry.upcomingHikes.isEmpty {
                Spacer()
                HStack {
                    Spacer()
                    VStack {
                        Image(systemName: "mountain.2")
                            .font(.title)
                            .foregroundColor(.secondary)
                        Text("No hikes yet")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }
                Spacer()
            } else {
                ForEach(entry.upcomingHikes.prefix(2)) { hike in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(hike.name)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .lineLimit(1)
                            
                            HStack {
                                Text(hike.totalWeight)
                                    .font(.caption)
                                Text("•")
                                    .font(.caption)
                                Text("\(hike.gearCount) items")
                                    .font(.caption)
                            }
                            .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        if hike.completed {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                        } else if hike.hasGear {
                            Image(systemName: "backpack.fill")
                                .foregroundColor(.accentColor)
                        } else {
                            Image(systemName: "backpack")
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            
            Spacer()
        }
        .padding()
    }
}

struct LargeWidgetView: View {
    let entry: HikeEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "mountain.2")
                    .foregroundColor(.accentColor)
                Text("Hike Summary")
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
                Text(entry.date, style: .time)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Statistics Row
            HStack(spacing: 20) {
                StatisticView(
                    title: "Total Hikes",
                    value: "\(entry.upcomingHikes.count)",
                    icon: "mountain.2"
                )
                
                StatisticView(
                    title: "Total Gear",
                    value: "\(entry.totalGearCount)",
                    icon: "backpack"
                )
                
                StatisticView(
                    title: "Avg Weight",
                    value: entry.averageWeight,
                    icon: "scalemass"
                )
            }
            
            Divider()
            
            // Hikes List
            if entry.upcomingHikes.isEmpty {
                VStack {
                    Image(systemName: "mountain.2")
                        .font(.title)
                        .foregroundColor(.secondary)
                    Text("No hikes planned")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    Text("Add your first hiking adventure")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ForEach(entry.upcomingHikes.prefix(4)) { hike in
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(hike.name)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .lineLimit(1)
                            
                            HStack {
                                Text("Total: \(hike.totalWeight)")
                                    .font(.caption2)
                                Text("•")
                                    .font(.caption2)
                                Text("Base: \(hike.baseWeight)")
                                    .font(.caption2)
                                Text("•")
                                    .font(.caption2)
                                Text("\(hike.gearCount) items")
                                    .font(.caption2)
                            }
                            .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        HStack(spacing: 8) {
                            if hike.hasGear {
                                Image(systemName: "backpack.fill")
                                    .foregroundColor(.accentColor)
                                    .font(.caption)
                            }
                            
                            if hike.completed {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                    .font(.caption)
                            }
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
            
            Spacer()
        }
        .padding()
    }
}

struct StatisticView: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .foregroundColor(.accentColor)
                .font(.caption)
            
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Widget Bundle

@main
struct PackPlannerWidgetBundle: WidgetBundle {
    var body: some Widget {
        PackPlannerWidget()
    }
}

#Preview("Small", as: .systemSmall) {
    PackPlannerWidget()
} timeline: {
    HikeEntry(
        date: Date(),
        upcomingHikes: [
            HikeWidgetData(
                name: "Mount Whitney Trail",
                totalWeight: "32.5 lb 4.2 oz",
                baseWeight: "18.2 lb 1.1 oz",
                gearCount: 24,
                completed: false,
                hasGear: true
            )
        ],
        totalGearCount: 45,
        averageWeight: "28.3 lb 2.1 oz"
    )
}

#Preview("Medium", as: .systemMedium) {
    PackPlannerWidget()
} timeline: {
    HikeEntry(
        date: Date(),
        upcomingHikes: [
            HikeWidgetData(
                name: "Mount Whitney Trail",
                totalWeight: "32.5 lb 4.2 oz",
                baseWeight: "18.2 lb 1.1 oz",
                gearCount: 24,
                completed: false,
                hasGear: true
            ),
            HikeWidgetData(
                name: "Half Dome",
                totalWeight: "28.1 lb 2.3 oz",
                baseWeight: "16.8 lb 0.9 oz",
                gearCount: 19,
                completed: true,
                hasGear: true
            )
        ],
        totalGearCount: 45,
        averageWeight: "28.3 lb 2.1 oz"
    )
}