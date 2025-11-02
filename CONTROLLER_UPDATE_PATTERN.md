# Controller Update Pattern Guide

This guide provides a systematic approach to updating your remaining controllers from Realm to Core Data.

## Overview

We've created Core Data versions of the three main controllers:
1. ✅ **HikeListController** - Main hike list with search
2. ✅ **GearListController** - Gear inventory
3. ✅ **GearBaseTableViewController** - Base class for gear tables

Use these as reference patterns for updating the remaining controllers.

---

## Universal Update Pattern

Every controller conversion follows this pattern:

### Step 1: Update Imports

**Replace:**
```swift
import RealmSwift
```

**With:**
```swift
import CoreData
```

### Step 2: Replace Realm References

| Realm | Core Data |
|-------|-----------|
| `var realm: Realm!` | `var context: NSManagedObjectContext { return CoreDataStack.shared.viewContext }` |
| `Results<Hike>` | `[HikeEntity]` or `NSFetchedResultsController<HikeEntity>` |
| `Results<Gear>` | `[GearEntity]` or array |
| `Gear` | `GearEntity` |
| `Hike` | `HikeEntity` |
| `HikeGear` | `HikeGearEntity` |
| `Settings` | `SettingsEntity` |

### Step 3: Replace Brain Classes

| Realm Brain | Core Data Brain |
|-------------|-----------------|
| `GearBrain` | `GearBrainCD` |
| `HikeBrain` | `HikeBrainCD` |
| `SettingsManager.SINGLETON` | `SettingsManagerCD.SINGLETON` |

### Step 4: Update Queries

**Realm:**
```swift
realm.objects(Hike.self)
realm.objects(Hike.self).filter("name CONTAINS[cd] %@", search)
```

**Core Data:**
```swift
let fetchRequest: NSFetchRequest<HikeEntity> = HikeEntity.fetchRequest()
fetchRequest.predicate = NSPredicate(format: "name CONTAINS[cd] %@", search)
let hikes = try context.fetch(fetchRequest)
```

### Step 5: Update Write Operations

**Realm:**
```swift
try realm.write {
    realm.add(object)
}
```

**Core Data:**
```swift
context.insert(object)
try context.save()
```

**Realm Delete:**
```swift
try realm.write {
    realm.delete(object)
}
```

**Core Data Delete:**
```swift
context.delete(object)
try context.save()
```

### Step 6: Add CloudKit Change Observer

Add this to `viewDidLoad()`:
```swift
NotificationCenter.default.addObserver(
    self,
    selector: #selector(handleCloudKitChange),
    name: .cloudKitDataChanged,
    object: nil
)
```

Add the handler method:
```swift
@objc private func handleCloudKitChange() {
    print("📡 CloudKit data changed, refreshing data")
    DispatchQueue.main.async { [weak self] in
        self?.refreshData() // Your refresh method
    }
}
```

Don't forget to remove observer in `deinit`:
```swift
deinit {
    NotificationCenter.default.removeObserver(self)
}
```

---

## Controller-Specific Patterns

### Pattern A: List Controllers (HikeListController, GearListController)

**Use NSFetchedResultsController for automatic updates:**

```swift
var fetchedResultsController: NSFetchedResultsController<EntityType>!

func setupFetchedResultsController() {
    let fetchRequest: NSFetchRequest<EntityType> = EntityType.fetchRequest()
    fetchRequest.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]

    fetchedResultsController = NSFetchedResultsController(
        fetchRequest: fetchRequest,
        managedObjectContext: context,
        sectionNameKeyPath: nil,
        cacheName: nil
    )

    fetchedResultsController.delegate = self

    do {
        try fetchedResultsController.performFetch()
    } catch {
        print("❌ Error fetching: \(error)")
    }
}

// Table view methods
override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return fetchedResultsController.fetchedObjects?.count ?? 0
}

override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = // dequeue cell
    let object = fetchedResultsController.object(at: indexPath)
    // configure cell
    return cell
}

// Implement NSFetchedResultsControllerDelegate
extension YourController: NSFetchedResultsControllerDelegate {
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.reloadData()
    }
}
```

### Pattern B: Detail/Edit Controllers

**Use simple fetch for single objects:**

```swift
var existingObject: EntityType?

override func viewDidLoad() {
    super.viewDidLoad()

    if let object = existingObject {
        // Load data from object
        loadData(from: object)
    }
}

func saveData() {
    if let existing = existingObject {
        // Edit existing
        existing.property = newValue
    } else {
        // Create new
        let new = EntityType(context: context)
        new.property = newValue
    }

    do {
        try context.save()
    } catch {
        print("❌ Error saving: \(error)")
    }
}
```

### Pattern C: Form Controllers (AddGearViewController, AddHikeViewController)

**Update Former forms to use Core Data:**

```swift
@IBOutlet weak var formContainer: UIView!
var existingEntity: EntityType?

private lazy var formerInputAccessoryView: FormerInputAccessoryView = {
    // Former setup
}()

override func viewDidLoad() {
    super.viewDidLoad()

    // Setup former
    former.append(sectionFormer: createFormSection())

    // Load existing data if editing
    if let entity = existingEntity {
        loadExistingData(entity)
    }
}

func saveAction() {
    let entity: EntityType

    if let existing = existingEntity {
        entity = existing
    } else {
        entity = EntityType(context: context)
    }

    // Update entity properties from form
    entity.property1 = value1
    entity.property2 = value2

    do {
        try context.save()
        // Post notification or dismiss
    } catch {
        print("❌ Error saving: \(error)")
    }
}
```

---

## Remaining Controllers to Update

### 1. HikeDetailViewController
**Pattern:** List Controller + Brain Class
**Key Changes:**
- Replace `HikeBrain(hike, pendingOnly)` with `HikeBrainCD(hike, pendingOnly)`
- Use `HikeEntity` instead of `Hike`
- Update weight calculation displays

### 2. AddGearViewController
**Pattern:** Form Controller
**Key Changes:**
- Replace `Gear()` with `GearEntity(context: context)`
- Update `setValues()` to work with Core Data
- Pass `imperial` parameter from `SettingsManagerCD`

### 3. AddHikeViewController
**Pattern:** Form Controller
**Key Changes:**
- Replace `Hike()` with `HikeEntity(context: context)`
- Update form bindings
- Save to Core Data context

### 4. AddGearToHikeTableViewController
**Pattern:** List Controller
**Key Changes:**
- Use `GearBrainCD.getFilteredGearsForExistingHike(hike:)`
- Create `HikeGearEntity` when adding gear
- Update `HikeBrainCD.createHikeGear(gear:hike:)`

### 5. EditHikeGearController
**Pattern:** Edit Controller
**Key Changes:**
- Accept `HikeGearEntity` instead of `HikeGear`
- Update quantity, worn, consumable, verified flags
- Call `context.save()` after changes

### 6. SettingsViewController
**Pattern:** Simple Controller
**Key Changes:**
- Use `SettingsManagerCD.SINGLETON`
- Update toggle methods
- Save changes to Core Data

### 7. HikeReportController
**Pattern:** Export Controller
**Key Changes:**
- Accept `HikeEntity` instead of `Hike`
- Update CSV export to read from Core Data entities
- Update weight calculations

---

## Cell Class Updates

### GearTableViewCell

**Add Core Data property:**
```swift
var existingGearCoreData: GearEntity? {
    didSet {
        guard let gear = existingGearCoreData else { return }
        nameLabel.text = gear.name
        weightLabel.text = gear.weightString(imperial: SettingsManagerCD.SINGLETON.settings.imperial)
        categoryLabel.text = gear.category
    }
}
```

### HikeListTableViewCell

**Add Core Data property:**
```swift
var existingHikeCoreData: HikeEntity? {
    didSet {
        guard let hike = existingHikeCoreData else { return }
        nameLabel.text = hike.name
        locationLabel.text = hike.location
        distanceLabel.text = hike.distance
        completedLabel.text = hike.completed ? "✓ Complete" : ""
    }
}
```

### HikeGearTableViewCell

**Add Core Data property:**
```swift
var existingHikeGearCoreData: HikeGearEntity? {
    didSet {
        guard let hikeGear = existingHikeGearCoreData else { return }
        nameLabel.text = hikeGear.gear?.name
        quantityLabel.text = "\(hikeGear.numberUnits)"
        weightLabel.text = hikeGear.totalWeightString(imperial: SettingsManagerCD.SINGLETON.settings.imperial)
        wornSwitch.isOn = hikeGear.worn
        consumableSwitch.isOn = hikeGear.consumable
    }
}
```

---

## SwiftUI DataService Update

Replace Realm queries with Core Data:

```swift
import CoreData

class DataService {
    static let shared = DataService()

    private var context: NSManagedObjectContext {
        return CoreDataStack.shared.viewContext
    }

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

    func createHike(name: String, desc: String, distance: String, location: String) -> HikeEntity {
        let hike = HikeEntity(context: context, name: name, desc: desc, distance: distance, location: location)

        do {
            try context.save()
        } catch {
            print("Error saving hike: \(error)")
        }

        return hike
    }

    func deleteHike(_ hike: HikeEntity) {
        context.delete(hike)

        do {
            try context.save()
        } catch {
            print("Error deleting hike: \(error)")
        }
    }

    // Similar methods for Gear...
}
```

---

## SwiftUI View Updates

Use `@FetchRequest` instead of `@State`:

**Before (Realm):**
```swift
@State private var hikes: [Hike] = []

var body: some View {
    List(hikes, id: \.self) { hike in
        // ...
    }
    .onAppear {
        loadHikes()
    }
}
```

**After (Core Data):**
```swift
@FetchRequest(
    sortDescriptors: [NSSortDescriptor(keyPath: \HikeEntity.name, ascending: true)],
    animation: .default)
private var hikes: FetchedResults<HikeEntity>

var body: some View {
    List(hikes) { hike in
        // ...
    }
}
```

---

## Testing Checklist

After updating each controller:

- [ ] Controller compiles without errors
- [ ] Data loads correctly
- [ ] Search/filter works
- [ ] Create new item works
- [ ] Edit existing item works
- [ ] Delete item works
- [ ] Cell displays correctly
- [ ] Navigation works
- [ ] Swipe actions work
- [ ] CloudKit sync updates view

---

## Common Issues & Solutions

### Issue: "Cannot find type 'Gear' in scope"
**Solution:** Replace with `GearEntity`

### Issue: "Value of type 'Results<Hike>' has no member 'filter'"
**Solution:** Use NSPredicate with NSFetchRequest instead

### Issue: "Cannot convert value of type 'Realm' to 'NSManagedObjectContext'"
**Solution:** Replace `realm` with `context`

### Issue: Cell not updating
**Solution:** Implement `NSFetchedResultsControllerDelegate`

### Issue: Data not syncing
**Solution:** Add CloudKit change observer

---

## Quick Reference

### Core Data CRUD Operations

**Create:**
```swift
let entity = EntityType(context: context)
entity.property = value
try context.save()
```

**Read:**
```swift
let fetchRequest: NSFetchRequest<EntityType> = EntityType.fetchRequest()
let results = try context.fetch(fetchRequest)
```

**Update:**
```swift
entity.property = newValue
try context.save()
```

**Delete:**
```swift
context.delete(entity)
try context.save()
```

---

## Next Steps

1. Start with **AddGearViewController** (simplest form)
2. Then **AddHikeViewController**
3. Move to **HikeDetailViewController** (most complex)
4. Update remaining controllers
5. Update cell classes
6. Update SwiftUI views
7. Test thoroughly

---

**Reference Examples:**
- `/PackPlanner/controllers/HikeListController_CoreData.swift`
- `/PackPlanner/controllers/GearListController_CoreData.swift`
- `/PackPlanner/controllers/GearBaseTableViewController_CoreData.swift`

These three files demonstrate all the patterns you need.
