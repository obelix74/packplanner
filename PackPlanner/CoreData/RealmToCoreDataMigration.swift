//
//  RealmToCoreDataMigration.swift
//  PackPlanner
//
//  Created for Core Data + CloudKit Migration
//

import Foundation
import CoreData
import RealmSwift

class RealmToCoreDataMigration {

    static let shared = RealmToCoreDataMigration()

    private let migrationKey = "HasMigratedToCoreData"
    private let realmBackupKey = "RealmBackupCompleted"

    private init() {}

    // MARK: - Public Methods

    /// Check if migration has already been completed
    func hasMigrated() -> Bool {
        return UserDefaults.standard.bool(forKey: migrationKey)
    }

    /// Mark migration as completed
    private func markMigrationComplete() {
        UserDefaults.standard.set(true, forKey: migrationKey)
        UserDefaults.standard.synchronize()
        print("✅ Migration marked as complete")
    }

    /// Perform the full migration
    func migrate(progressHandler: ((String, Double) -> Void)? = nil, completion: @escaping (Bool, Error?) -> Void) {

        // Check if already migrated
        if hasMigrated() {
            print("ℹ️ Migration already completed")
            completion(true, nil)
            return
        }

        print("🚀 Starting Realm to Core Data migration...")
        progressHandler?("Starting migration...", 0.0)

        // Perform migration on background thread
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                // Open Realm
                let realm = try Realm()

                // Get all data
                let gears = Array(realm.objects(Gear.self))
                let hikes = Array(realm.objects(Hike.self))
                let settings = realm.objects(Settings.self).first

                let totalItems = gears.count + hikes.count + 1
                var processedItems = 0

                print("📊 Found \(gears.count) gears, \(hikes.count) hikes to migrate")

                // Create background context
                let context = CoreDataStack.shared.newBackgroundContext()

                // Create UUID mapping for Gear objects
                var gearMapping: [String: GearEntity] = [:]

                // Step 1: Migrate Settings (10% of progress)
                progressHandler?("Migrating settings...", 0.1)
                if let realmSettings = settings {
                    self.migrateSettings(realmSettings, context: context)
                    print("✅ Settings migrated")
                } else {
                    // Create default settings
                    _ = SettingsEntity.fetchOrCreate(context: context)
                    print("✅ Default settings created")
                }
                processedItems += 1

                // Step 2: Migrate Gears (10-50% of progress)
                progressHandler?("Migrating gear items...", 0.2)
                for (index, gear) in gears.enumerated() {
                    let gearEntity = self.migrateGear(gear, context: context)
                    gearMapping[gear.uuid] = gearEntity

                    processedItems += 1
                    let progress = 0.1 + (Double(processedItems) / Double(totalItems)) * 0.4
                    if index % 10 == 0 {
                        progressHandler?("Migrating gear items... \(index + 1)/\(gears.count)", progress)
                    }
                }
                print("✅ Migrated \(gears.count) gear items")

                // Save gears before migrating hikes
                try context.save()
                print("💾 Saved gear items to Core Data")

                // Step 3: Migrate Hikes and HikeGears (50-90% of progress)
                progressHandler?("Migrating hikes...", 0.5)
                for (index, hike) in hikes.enumerated() {
                    self.migrateHike(hike, context: context, gearMapping: gearMapping)

                    processedItems += 1
                    let progress = 0.5 + (Double(processedItems) / Double(totalItems)) * 0.4
                    if index % 5 == 0 {
                        progressHandler?("Migrating hikes... \(index + 1)/\(hikes.count)", progress)
                    }
                }
                print("✅ Migrated \(hikes.count) hikes")

                // Final save
                progressHandler?("Saving data...", 0.95)
                try context.save()
                print("💾 All data saved to Core Data")

                // Mark migration as complete
                self.markMigrationComplete()

                // Success
                progressHandler?("Migration complete!", 1.0)
                DispatchQueue.main.async {
                    completion(true, nil)
                }

            } catch {
                print("❌ Migration failed: \(error)")
                DispatchQueue.main.async {
                    progressHandler?("Migration failed", 0.0)
                    completion(false, error)
                }
            }
        }
    }

    // MARK: - Private Migration Methods

    private func migrateSettings(_ realmSettings: Settings, context: NSManagedObjectContext) {
        let settingsEntity = SettingsEntity.fetchOrCreate(context: context)
        settingsEntity.imperial = realmSettings.imperial
        settingsEntity.firstTimeUser = realmSettings.firstTimeUser
    }

    private func migrateGear(_ realmGear: Gear, context: NSManagedObjectContext) -> GearEntity {
        let gearEntity = GearEntity(context: context)
        gearEntity.name = realmGear.name
        gearEntity.desc = realmGear.desc
        gearEntity.weightInGrams = realmGear.weightInGrams
        gearEntity.category = realmGear.category
        gearEntity.uuid = realmGear.uuid.isEmpty ? UUID().uuidString : realmGear.uuid
        return gearEntity
    }

    private func migrateHike(_ realmHike: Hike, context: NSManagedObjectContext, gearMapping: [String: GearEntity]) {
        let hikeEntity = HikeEntity(context: context)
        hikeEntity.name = realmHike.name
        hikeEntity.desc = realmHike.desc
        hikeEntity.distance = realmHike.distance
        hikeEntity.location = realmHike.location
        hikeEntity.completed = realmHike.completed
        hikeEntity.externalLink1 = realmHike.externalLink1
        hikeEntity.externalLink2 = realmHike.externalLink2
        hikeEntity.externalLink3 = realmHike.externalLink3

        // Migrate HikeGear relationships
        for realmHikeGear in realmHike.hikeGears {
            if let realmGear = realmHikeGear.gear,
               let gearEntity = gearMapping[realmGear.uuid] {

                let hikeGearEntity = HikeGearEntity(context: context)
                hikeGearEntity.gear = gearEntity
                hikeGearEntity.hike = hikeEntity
                hikeGearEntity.consumable = realmHikeGear.consumable
                hikeGearEntity.worn = realmHikeGear.worn
                hikeGearEntity.numberUnits = Int32(realmHikeGear.numberUnits)
                hikeGearEntity.verified = realmHikeGear.verified
                hikeGearEntity.notes = realmHikeGear.notes

                hikeEntity.addToHikeGears(hikeGearEntity)
            }
        }
    }

    // MARK: - Backup & Rollback

    /// Create a backup of Realm file (optional safety measure)
    func backupRealmFile() -> Bool {
        guard let realmURL = Realm.Configuration.defaultConfiguration.fileURL else {
            print("❌ Could not find Realm file URL")
            return false
        }

        let backupURL = realmURL.deletingLastPathComponent().appendingPathComponent("default.realm.backup")

        do {
            // Remove existing backup
            if FileManager.default.fileExists(atPath: backupURL.path) {
                try FileManager.default.removeItem(at: backupURL)
            }

            // Copy current Realm to backup
            try FileManager.default.copyItem(at: realmURL, to: backupURL)
            UserDefaults.standard.set(true, forKey: realmBackupKey)
            print("✅ Realm backup created at: \(backupURL.path)")
            return true
        } catch {
            print("❌ Failed to backup Realm: \(error)")
            return false
        }
    }

    /// Reset migration flag (for testing)
    func resetMigration() {
        UserDefaults.standard.removeObject(forKey: migrationKey)
        UserDefaults.standard.removeObject(forKey: realmBackupKey)
        print("⚠️ Migration flags reset")
    }

    /// Delete Core Data and reset (for testing)
    func deleteCoreDataStore() {
        let context = CoreDataStack.shared.viewContext
        CoreDataStack.shared.deleteAllData()
        print("⚠️ Core Data store deleted")
    }
}
