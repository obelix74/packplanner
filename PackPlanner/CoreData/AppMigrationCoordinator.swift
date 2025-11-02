//
//  AppMigrationCoordinator.swift
//  PackPlanner
//
//  Coordinates migration check and execution on app launch
//

import UIKit

class AppMigrationCoordinator {

    static let shared = AppMigrationCoordinator()

    private init() {}

    /// Check if migration is needed and present migration UI if necessary
    /// Returns true if migration is needed, false otherwise
    func checkAndMigrateIfNeeded(from window: UIWindow?, completion: @escaping (Bool) -> Void) {

        // Check if migration has already been completed
        if RealmToCoreDataMigration.shared.hasMigrated() {
            print("ℹ️ Migration already completed, skipping...")
            completion(true)
            return
        }

        // Check if Realm database exists and has data
        guard realmDatabaseExists() && realmHasData() else {
            print("ℹ️ No Realm data found, marking migration as complete")
            // Mark as migrated since there's no data to migrate
            UserDefaults.standard.set(true, forKey: "HasMigratedToCoreData")
            UserDefaults.standard.synchronize()
            completion(true)
            return
        }

        print("🔄 Realm data found, migration needed")

        // Present migration UI
        presentMigrationUI(from: window, completion: completion)
    }

    // MARK: - Private Methods

    private func realmDatabaseExists() -> Bool {
        do {
            let realm = try Realm()
            return true
        } catch {
            print("⚠️ Could not open Realm database: \(error)")
            return false
        }
    }

    private func realmHasData() -> Bool {
        do {
            let realm = try Realm()
            let gearCount = realm.objects(Gear.self).count
            let hikeCount = realm.objects(Hike.self).count

            print("📊 Realm database contains: \(gearCount) gears, \(hikeCount) hikes")

            return gearCount > 0 || hikeCount > 0
        } catch {
            print("⚠️ Could not check Realm data: \(error)")
            return false
        }
    }

    private func presentMigrationUI(from window: UIWindow?, completion: @escaping (Bool) -> Void) {
        guard let window = window else {
            print("❌ No window available for migration UI")
            completion(false)
            return
        }

        // Create migration view controller
        let migrationVC = MigrationViewController()
        migrationVC.modalPresentationStyle = .fullScreen

        migrationVC.onMigrationComplete = {
            // Dismiss migration UI
            migrationVC.dismiss(animated: true) {
                print("✅ Migration UI dismissed, app ready to use")
                completion(true)
            }
        }

        // Present migration UI
        DispatchQueue.main.async {
            if let rootVC = window.rootViewController {
                rootVC.present(migrationVC, animated: false)
            } else {
                // If no root view controller yet, set migration VC as root temporarily
                window.rootViewController = migrationVC
                window.makeKeyAndVisible()

                // After migration, we'll need to reset the root VC
                migrationVC.onMigrationComplete = {
                    print("✅ Migration complete, app will set proper root VC")
                    completion(true)
                }
            }
        }
    }

    // MARK: - Development Helpers

    /// Reset migration flag (for testing)
    func resetMigration() {
        RealmToCoreDataMigration.shared.resetMigration()
    }

    /// Force migration UI (for testing)
    func forceMigration(from window: UIWindow?, completion: @escaping (Bool) -> Void) {
        presentMigrationUI(from: window, completion: completion)
    }
}

// Need to import RealmSwift for Realm checks
import RealmSwift
