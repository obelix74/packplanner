//
//  SettingsManager.swift
//  PackPlanner
//
//  Created by Kumar on 9/20/20.
//

import Foundation
import RealmSwift

// Force Realm configuration to be set up early
private let _realmConfig: Void = {
    print("Configuring Realm early from SettingsManager...")
    let config = Realm.Configuration(
        schemaVersion: 1,
        migrationBlock: { migration, oldSchemaVersion in
            print("Migration block called: oldSchemaVersion=\(oldSchemaVersion), newSchemaVersion=1")
            
            if oldSchemaVersion < 1 {
                print("Migrating Realm from schema version \(oldSchemaVersion) to 1")
                
                // Handle migration from gearList to gear property
                migration.enumerateObjects(ofType: HikeGear.className()) { oldObject, newObject in
                    print("Processing HikeGear migration...")
                    
                    // Try to get the gearList from old object
                    if let gearList = oldObject?["gearList"] {
                        print("Found gearList in old object: \(gearList)")
                        
                        // Handle both List<DynamicObject> and List<Gear> cases
                        if let dynamicList = gearList as? List<DynamicObject>, let firstGear = dynamicList.first {
                            newObject?["gear"] = firstGear
                            print("Migrated HikeGear: moved first gear from DynamicObject list to gear property")
                        } else if let results = gearList as? Results<DynamicObject>, let firstGear = results.first {
                            newObject?["gear"] = firstGear
                            print("Migrated HikeGear: moved first gear from Results to gear property")
                        } else {
                            print("Could not convert gearList to known type: \(type(of: gearList))")
                        }
                    } else {
                        print("No gearList found in old object")
                        // Set gear to nil if no gearList exists
                        newObject?["gear"] = nil
                    }
                }
                
                print("HikeGear migration completed")
            }
        },
        deleteRealmIfMigrationNeeded: true  // TEMPORARY: Delete and recreate if migration fails
    )
    Realm.Configuration.defaultConfiguration = config
    print("Realm configuration completed successfully with schema version 1")
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
                    fatalError("Fatal: SettingsManager cannot initialize any Realm database. App cannot continue: \(error)")
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
