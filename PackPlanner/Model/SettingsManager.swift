//
//  SettingsManager.swift
//  PackPlanner
//
//  Created by Kumar on 9/20/20.
//

import Foundation
import RealmSwift

// Force Realm configuration to be set up early with enhanced error handling
private let _realmConfig: Void = {
    print("Configuring Realm early from SettingsManager...")
    
    // Create backup configuration as fallback
    let createSafeConfig = { () -> Realm.Configuration in
        return Realm.Configuration(
            schemaVersion: 1,
            migrationBlock: { migration, oldSchemaVersion in
                print("Migration block called: oldSchemaVersion=\(oldSchemaVersion), newSchemaVersion=1")
                
                if oldSchemaVersion < 1 {
                    print("Migrating Realm from schema version \(oldSchemaVersion) to 1")
                    
                    var migrationCount = 0
                    var successCount = 0
                    
                    // Handle migration from gearList to gear property with validation
                    migration.enumerateObjects(ofType: HikeGear.className()) { oldObject, newObject in
                        migrationCount += 1
                        print("Processing HikeGear migration #\(migrationCount)...")
                        
                        // Try to get the gearList from old object
                        if let gearList = oldObject?["gearList"] {
                            print("Found gearList in old object: \(gearList)")
                            
                            // Handle both List<DynamicObject> and List<Gear> cases
                            if let dynamicList = gearList as? List<DynamicObject>, let firstGear = dynamicList.first {
                                newObject?["gear"] = firstGear
                                successCount += 1
                                print("Migrated HikeGear: moved first gear from DynamicObject list to gear property")
                            } else if let results = gearList as? Results<DynamicObject>, let firstGear = results.first {
                                newObject?["gear"] = firstGear
                                successCount += 1
                                print("Migrated HikeGear: moved first gear from Results to gear property")
                            } else {
                                print("Could not convert gearList to known type: \(type(of: gearList))")
                                // Set gear to nil if conversion fails
                                newObject?["gear"] = nil
                                successCount += 1
                            }
                        } else {
                            print("No gearList found in old object")
                            // Set gear to nil if no gearList exists
                            newObject?["gear"] = nil
                            successCount += 1
                        }
                    }
                    
                    print("HikeGear migration completed: \(successCount)/\(migrationCount) objects migrated successfully")
                    
                    // Validate migration results
                    if migrationCount > 0 && successCount < migrationCount {
                        print("Warning: Migration incomplete - some objects may not have migrated properly")
                    }
                }
            },
            deleteRealmIfMigrationNeeded: true  // Delete and recreate if migration fails
        )
    }
    
    do {
        let config = createSafeConfig()
        
        // Test the configuration by creating a temporary Realm instance
        let testRealm = try Realm(configuration: config)
        testRealm.invalidate() // Clean up test instance
        
        // If successful, set as default
        Realm.Configuration.defaultConfiguration = config
        print("Realm configuration completed successfully with schema version 1")
        
    } catch {
        print("Failed to validate Realm configuration: \(error)")
        
        // Fallback to safe configuration without migration
        let fallbackConfig = Realm.Configuration(
            schemaVersion: 1,
            deleteRealmIfMigrationNeeded: true
        )
        
        do {
            let testRealm = try Realm(configuration: fallbackConfig)
            testRealm.invalidate()
            Realm.Configuration.defaultConfiguration = fallbackConfig
            print("Using fallback Realm configuration (database will be reset)")
        } catch {
            print("Even fallback configuration failed: \(error)")
            // This will be handled by the SettingsManager init
        }
    }
}()

class SettingsManager {
    
    private let realm: Realm
    static let SINGLETON = SettingsManager()
    var settings: Settings = Settings()
    
    private init() {
        // Force the configuration to be set up
        _ = _realmConfig
        
        print("SettingsManager initializing with configuration: \(Realm.Configuration.defaultConfiguration.schemaVersion)")
        
        do {
            // Use the default configuration that should already be set
            self.realm = try Realm()
            print("SettingsManager successfully initialized Realm")
        } catch {
            print("Critical: Failed to initialize Realm in SettingsManager: \(error)")
            print("Default config schema version: \(Realm.Configuration.defaultConfiguration.schemaVersion)")
            
            // Attempt to use the configuration directly
            do {
                let config = Realm.Configuration(
                    schemaVersion: 1,
                    migrationBlock: { migration, oldSchemaVersion in
                        if oldSchemaVersion < 1 {
                            print("Running migration in fallback: \(oldSchemaVersion) to 1")
                            migration.enumerateObjects(ofType: HikeGear.className()) { oldObject, newObject in
                                if let gearList = oldObject?["gearList"] as? List<DynamicObject>,
                                   let firstGear = gearList.first {
                                    newObject?["gear"] = firstGear
                                    print("Migrated HikeGear in fallback")
                                }
                            }
                        }
                    }
                )
                self.realm = try Realm(configuration: config)
                print("SettingsManager initialized with explicit migration config")
            } catch {
                print("Even explicit config failed: \(error)")
                // Final fallback to in-memory realm
                do {
                    let fallbackConfig = Realm.Configuration(
                        inMemoryIdentifier: "settings_fallback",
                        schemaVersion: 1
                    )
                    self.realm = try Realm(configuration: fallbackConfig)
                    print("SettingsManager using in-memory database fallback")
                } catch {
                    print("Critical: SettingsManager fallback Realm initialization failed: \(error)")
                    // Create an empty in-memory realm as last resort
                    let emptyConfig = Realm.Configuration(
                        inMemoryIdentifier: "settings_emergency_\(UUID().uuidString)",
                        schemaVersion: 1
                    )
                    do {
                        self.realm = try Realm(configuration: emptyConfig)
                        print("SettingsManager using emergency empty database")
                    } catch {
                        // If even this fails, we can't continue - but let's not crash
                        // Instead, we'll throw an error that can be caught
                        preconditionFailure("Critical: Cannot initialize any database. Please restart the app.")
                    }
                }
            }
        }
        
        let results : Results<Settings> = realm.objects(Settings.self)
        if (results.count == 0) {
            do {
                try realm.write {
                    realm.add(settings)
                }
            } catch {
                print("Error creating settings \(error)")
            }
        } else {
            self.settings = results.first!
        }
    }
    
    func weightUnitString() -> String {
        return self.settings.imperial ? "(Oz)" : "(Grams)"
    }
    
    func setFirstTimeUser() {
        do {
            try realm.write {
                self.settings.firstTimeUser = false
            }
        } catch {
            print("Error updating first time user \(error)")
        }
    }
}
