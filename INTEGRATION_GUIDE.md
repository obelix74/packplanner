# Core Data + CloudKit Integration Guide

This guide explains how to integrate the new Core Data + CloudKit system into your existing PackPlanner app.

## Overview

We've created a complete Core Data + CloudKit implementation that runs alongside your existing Realm setup. This allows for:
- Automatic one-time migration from Realm to Core Data
- CloudKit sync across devices
- Backward compatibility during transition

---

## Phase 1: AppDelegate Integration (REQUIRED FIRST)

### 1. Update AppDelegate.swift

Find your `application(_:didFinishLaunchingWithOptions:)` method and add migration check:

```swift
import UIKit
import CoreData

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        // Check for migration BEFORE setting up UI
        if let window = window {
            AppMigrationCoordinator.shared.checkAndMigrateIfNeeded(from: window) { success in
                if success {
                    print("✅ App ready to use")
                    // Migration complete or not needed, app continues normally
                } else {
                    print("⚠️ Migration failed, app may have issues")
                    // Handle failure case - maybe show an alert
                }
            }
        }

        // Rest of your existing code...
        return true
    }
}
```

**Important:** This MUST be done before the app UI is fully initialized. The migration check will:
- Detect if Realm data exists
- Present migration UI automatically if needed
- Complete migration before user can use the app

---

## Phase 2: Xcode Project Configuration

### 1. Add Core Data Files to Project

In Xcode, add all files from `/PackPlanner/CoreData/` to your project:

**Core Data Stack:**
- `CoreDataStack.swift`
- `AppMigrationCoordinator.swift`
- `RealmToCoreDataMigration.swift`
- `MigrationViewController.swift`

**Entity Classes:**
- `GearEntity+CoreDataClass.swift`
- `GearEntity+CoreDataProperties.swift`
- `HikeEntity+CoreDataClass.swift`
- `HikeEntity+CoreDataProperties.swift`
- `HikeGearEntity+CoreDataClass.swift`
- `HikeGearEntity+CoreDataProperties.swift`
- `SettingsEntity+CoreDataClass.swift`
- `SettingsEntity+CoreDataProperties.swift`

**Business Logic:**
- `GearBrainCD.swift`
- `HikeBrainCD.swift`
- `SettingsManagerCD.swift`

### 2. Create Core Data Model

Follow the detailed instructions in `COREDATA_SETUP_INSTRUCTIONS.md` to:
1. Create `PackPlanner.xcdatamodeld` file
2. Add all entities (GearEntity, HikeEntity, HikeGearEntity, SettingsEntity)
3. Configure relationships
4. Mark entities for CloudKit

### 3. Configure CloudKit

Follow the detailed instructions in `CLOUDKIT_CONFIGURATION.md` to:
1. Enable iCloud capability
2. Configure CloudKit container
3. Add background modes
4. Test CloudKit status

---

## Phase 3: Controller Migration (Gradual)

You can migrate controllers gradually. Here's the strategy:

### Strategy: Dual-Mode Controllers

For each controller, you can support both Realm and Core Data temporarily:

```swift
class HikeListController: UITableViewController {

    // Realm (existing)
    var realm: Realm!
    var hikeResults: Results<Hike>?

    // Core Data (new)
    var useCoreData = true  // Toggle this
    var fetchedResultsController: NSFetchedResultsController<HikeEntity>?

    override func viewDidLoad() {
        super.viewDidLoad()

        if useCoreData {
            setupCoreData()
        } else {
            setupRealm()
        }
    }

    func setupCoreData() {
        let fetchRequest: NSFetchRequest<HikeEntity> = HikeEntity.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]

        fetchedResultsController = NSFetchedResultsController(
            fetchRequest: fetchRequest,
            managedObjectContext: CoreDataStack.shared.viewContext,
            sectionNameKeyPath: nil,
            cacheName: nil
        )

        fetchedResultsController?.delegate = self

        do {
            try fetchedResultsController?.performFetch()
        } catch {
            print("Error fetching: \(error)")
        }
    }

    func setupRealm() {
        // Existing Realm code...
    }

    // Update table view methods to check useCoreData flag
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if useCoreData {
            return fetchedResultsController?.fetchedObjects?.count ?? 0
        } else {
            return hikeResults?.count ?? 0
        }
    }
}

// Implement NSFetchedResultsControllerDelegate
extension HikeListController: NSFetchedResultsControllerDelegate {
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.reloadData()
    }
}
```

### Example: Migrating HikeListController

**Before (Realm):**
```swift
let gearBrain = GearBrain.getFilteredGears(search: searchText)
```

**After (Core Data):**
```swift
let gearBrain = GearBrainCD.getFilteredGears(search: searchText)
```

**Key Changes:**
1. Replace `Realm` with `NSManagedObjectContext`
2. Replace `Results<T>` with `NSFetchedResultsController<T>` or `[T]`
3. Replace `GearBrain` with `GearBrainCD`
4. Replace `HikeBrain` with `HikeBrainCD`
5. Replace `SettingsManager.SINGLETON` with `SettingsManagerCD.SINGLETON`

---

## Phase 4: SwiftUI Integration

Your existing SwiftUI views need updating to use Core Data:

### Update DataService.swift

```swift
import CoreData

class DataService {
    static let shared = DataService()

    private var context: NSManagedObjectContext {
        return CoreDataStack.shared.viewContext
    }

    // Update all methods to use Core Data instead of Realm

    func fetchAllHikes() -> [HikeEntity] {
        let fetchRequest: NSFetchRequest<HikeEntity> = HikeEntity.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]

        do {
            return try context.fetch(fetchRequest)
        } catch {
            print("Error fetching hikes: \(error)")
            return []
        }
    }

    func fetchAllGears() -> [GearEntity] {
        let fetchRequest: NSFetchRequest<GearEntity> = GearEntity.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]

        do {
            return try context.fetch(fetchRequest)
        } catch {
            print("Error fetching gears: \(error)")
            return []
        }
    }

    // ... etc
}
```

### Use @FetchRequest in SwiftUI Views

```swift
import SwiftUI
import CoreData

struct HikeListView: View {
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \HikeEntity.name, ascending: true)],
        animation: .default)
    private var hikes: FetchedResults<HikeEntity>

    var body: some View {
        List(hikes) { hike in
            HikeRow(hike: hike)
        }
    }
}
```

---

## Phase 5: Testing Migration

### Test Plan:

1. **Install app with Realm data**
   - Use existing version with Realm
   - Add test data (gears, hikes)

2. **Update to Core Data version**
   - Install new version with Core Data
   - App should automatically show migration UI
   - Verify all data migrated correctly

3. **Verify CloudKit sync**
   - Create new data on Device 1
   - Wait for sync
   - Check Device 2 for synced data

4. **Test offline/online**
   - Turn off WiFi
   - Make changes
   - Turn WiFi back on
   - Verify changes sync

### Testing Checklist:

- [ ] Migration completes without errors
- [ ] All gears migrated
- [ ] All hikes migrated with correct gear associations
- [ ] Settings preserved (imperial/metric, first-time user)
- [ ] Weight calculations correct
- [ ] Categories display correctly
- [ ] Search works
- [ ] Create new gear works
- [ ] Create new hike works
- [ ] Edit operations work
- [ ] Delete operations work
- [ ] CloudKit sync works
- [ ] Multi-device sync works

---

## Phase 6: Cleanup (After Successful Migration)

After thoroughly testing and confirming Core Data works:

### 1. Remove Realm Dependency

In `Podfile`, remove:
```ruby
pod 'RealmSwift'
```

Run:
```bash
pod install
```

### 2. Delete Realm Files

You can safely delete:
- `PackPlanner/Model/Gear.swift` (old Realm model)
- `PackPlanner/Model/Hike.swift` (old Realm model)
- `PackPlanner/Model/HikeGear.swift` (old Realm model)
- `PackPlanner/Model/Settings.swift` (old Realm model)
- `PackPlanner/Model/GearBrain.swift` (old version)
- `PackPlanner/Model/HikeBrain.swift` (old version)
- `PackPlanner/Model/SettingsManager.swift` (old version)

### 3. Update All Controller Imports

Replace:
```swift
import RealmSwift
```

With:
```swift
import CoreData
```

---

## Rollback Plan

If you need to rollback to Realm:

1. Keep Realm files in the project
2. Set `useCoreData = false` in controllers
3. User data is preserved in Realm (migration doesn't delete it)

---

## Architecture Comparison

### Before (Realm):
```
Realm DB
  ↓
Gear, Hike, HikeGear, Settings (Realm Objects)
  ↓
GearBrain, HikeBrain, SettingsManager
  ↓
Controllers/Views
```

### After (Core Data + CloudKit):
```
Core Data + CloudKit Sync
  ↓
GearEntity, HikeEntity, HikeGearEntity, SettingsEntity (NSManagedObject)
  ↓
GearBrainCD, HikeBrainCD, SettingsManagerCD
  ↓
Controllers/Views
```

---

## Key Benefits

1. **iCloud Sync**: Automatic sync across devices
2. **Conflict Resolution**: CloudKit handles merge conflicts
3. **Offline Support**: Works without internet, syncs when available
4. **Apple Integration**: Native iOS technology stack
5. **Scalability**: Better performance for large datasets
6. **Future-Proof**: Core Data + CloudKit is Apple's recommended approach

---

## Support & Troubleshooting

### Common Issues:

**Issue: Migration fails**
- Check console for specific error
- Verify Realm database is accessible
- Try `RealmToCoreDataMigration.shared.resetMigration()` and retry

**Issue: CloudKit not syncing**
- Verify iCloud is enabled in Settings
- Check internet connection
- Wait 30-60 seconds for sync
- Check CloudKit Dashboard for errors

**Issue: Duplicate data**
- Run `GearBrainCD.cleanupDuplicateGears()`
- Check UUID assignment during migration

---

## Next Steps

1. ✅ Complete AppDelegate integration (Phase 1)
2. ✅ Create Core Data model in Xcode (Phase 2)
3. ✅ Configure CloudKit (Phase 2)
4. 🔄 Gradually migrate controllers (Phase 3)
5. 🔄 Update SwiftUI views (Phase 4)
6. 🧪 Test thoroughly (Phase 5)
7. 🗑️ Clean up Realm code (Phase 6)

---

## Questions?

Refer to:
- `COREDATA_SETUP_INSTRUCTIONS.md` - Model creation
- `CLOUDKIT_CONFIGURATION.md` - CloudKit setup
- Core Data files in `/PackPlanner/CoreData/` - Implementation details
