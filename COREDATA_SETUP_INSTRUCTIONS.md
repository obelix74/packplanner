# Core Data Model Setup Instructions

Follow these steps in Xcode to create the Core Data model.

## Step 1: Create Core Data Model File

1. Open `PackPlanner.xcworkspace` in Xcode
2. Right-click on the `PackPlanner` folder in Project Navigator
3. Select `New File...`
4. Choose `Data Model` under Core Data
5. Name it `PackPlanner` (this creates `PackPlanner.xcdatamodeld`)
6. Click Create

## Step 2: Create Entities

### A. GearEntity

1. Click the `+ Entity` button at the bottom
2. Name it `GearEntity`
3. Add Attributes:
   - `name` - String (non-optional)
   - `desc` - String (non-optional, default value: "")
   - `weightInGrams` - Double (non-optional, default value: 0)
   - `category` - String (non-optional, default value: "Unknown")
   - `uuid` - String (non-optional)
4. Add Relationship:
   - `hikeGears` - To-Many relationship to `HikeGearEntity`
   - Inverse: `gear`
   - Delete Rule: Nullify
5. Under the Data Model Inspector (right panel):
   - Click on `uuid` attribute
   - Check "Index in Spotlight"
   - This will be used for lookups

### B. HikeEntity

1. Click `+ Entity`
2. Name it `HikeEntity`
3. Add Attributes:
   - `name` - String (non-optional)
   - `desc` - String (non-optional, default value: "")
   - `distance` - String (non-optional, default value: "")
   - `location` - String (non-optional, default value: "")
   - `completed` - Boolean (non-optional, default value: NO)
   - `externalLink1` - String (optional)
   - `externalLink2` - String (optional)
   - `externalLink3` - String (optional)
4. Add Relationship:
   - `hikeGears` - To-Many relationship to `HikeGearEntity`
   - Inverse: `hike`
   - Delete Rule: Cascade (when hike is deleted, delete all associated HikeGear)

### C. HikeGearEntity

1. Click `+ Entity`
2. Name it `HikeGearEntity`
3. Add Attributes:
   - `consumable` - Boolean (non-optional, default value: NO)
   - `worn` - Boolean (non-optional, default value: NO)
   - `numberUnits` - Integer 32 (non-optional, default value: 1)
   - `verified` - Boolean (non-optional, default value: NO)
   - `notes` - String (non-optional, default value: "")
4. Add Relationships:
   - `gear` - To-One relationship to `GearEntity`
     - Inverse: `hikeGears`
     - Delete Rule: Nullify
   - `hike` - To-One relationship to `HikeEntity`
     - Inverse: `hikeGears`
     - Delete Rule: Nullify

### D. SettingsEntity

1. Click `+ Entity`
2. Name it `SettingsEntity`
3. Add Attributes:
   - `imperial` - Boolean (non-optional, default value: YES)
   - `firstTimeUser` - Boolean (non-optional, default value: YES)

## Step 3: Configure CloudKit

For each Entity (GearEntity, HikeEntity, HikeGearEntity, SettingsEntity):

1. Select the entity
2. In the Data Model Inspector (right panel):
   - Check "Used with CloudKit"
   - This enables automatic CloudKit schema generation

## Step 4: Generate NSManagedObject Subclasses

**SKIP THIS STEP** - I've already created the classes manually for better control.

The classes are located in:
- `/PackPlanner/CoreData/GearEntity+CoreDataClass.swift`
- `/PackPlanner/CoreData/GearEntity+CoreDataProperties.swift`
- (and similar for other entities)

## Step 5: Verify Model Configuration

1. Select `PackPlanner.xcdatamodeld` in Project Navigator
2. Select Editor → Create NSManagedObject Subclass (but cancel it - just checking)
3. Verify all entities show the green CloudKit icon (if configured)

## Step 6: Build Project

1. Press `Cmd+B` to build
2. Fix any issues that arise
3. Verify no errors related to Core Data

---

## Important Notes

- The CloudKit container identifier in `CoreDataStack.swift` is set to `iCloud.com.anand.PackPlanner`
- You may need to adjust this based on your Apple Developer account and app bundle ID
- Relationships must have inverse relationships defined (required by Core Data)
- Delete rules are important:
  - Hike → HikeGears: Cascade (delete gear associations when hike deleted)
  - Gear → HikeGears: Nullify (keep gear when associations deleted)
  - HikeGear → Gear/Hike: Nullify (don't delete parent when association deleted)

---

## Next Steps

After completing these steps, proceed with:
1. Configuring CloudKit capabilities in Xcode
2. Implementing the data migration service
