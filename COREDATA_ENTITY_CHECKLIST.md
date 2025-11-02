# Core Data Entity Creation Checklist

Follow this checklist step-by-step. Check each box as you complete it.

---

## ENTITY 1: GearEntity

### Create Entity
- [ ] Click "+ Add Entity" button (bottom left)
- [ ] Double-click "Entity" to rename
- [ ] Type: `GearEntity`
- [ ] Press Enter

### Add Attributes (Click "+ " button 5 times)

**Attribute 1:**
- [ ] Name: `name`
- [ ] Type: `String`
- [ ] Uncheck "Optional" (in right panel)

**Attribute 2:**
- [ ] Name: `desc`
- [ ] Type: `String`
- [ ] Uncheck "Optional"

**Attribute 3:**
- [ ] Name: `weightInGrams`
- [ ] Type: `Double`
- [ ] Uncheck "Optional"
- [ ] Default Value: `0`

**Attribute 4:**
- [ ] Name: `category`
- [ ] Type: `String`
- [ ] Uncheck "Optional"
- [ ] Default Value: `Unknown`

**Attribute 5:**
- [ ] Name: `uuid`
- [ ] Type: `String`
- [ ] Uncheck "Optional"

### Add Relationship
- [ ] Click "Add Relationship" button (bottom left, next to Add Attribute)
- [ ] Name: `hikeGears`
- [ ] Destination: `HikeGearEntity` (we'll create this next)
- [ ] Type: To Many (check the box in right panel)
- [ ] Inverse: `gear` (we'll set this later)
- [ ] Delete Rule: `Nullify`

### Enable CloudKit
- [ ] With GearEntity selected, in Data Model Inspector (right panel)
- [ ] Check ☑️ "Used with CloudKit"

---

## ENTITY 2: HikeEntity

### Create Entity
- [ ] Click "+ Add Entity" button
- [ ] Rename to: `HikeEntity`

### Add Attributes (Click "+ " button 8 times)

**Attribute 1:**
- [ ] Name: `name`
- [ ] Type: `String`
- [ ] Uncheck "Optional"

**Attribute 2:**
- [ ] Name: `desc`
- [ ] Type: `String`
- [ ] Uncheck "Optional"

**Attribute 3:**
- [ ] Name: `distance`
- [ ] Type: `String`
- [ ] Uncheck "Optional"

**Attribute 4:**
- [ ] Name: `location`
- [ ] Type: `String`
- [ ] Uncheck "Optional"

**Attribute 5:**
- [ ] Name: `completed`
- [ ] Type: `Boolean`
- [ ] Uncheck "Optional"
- [ ] Default Value: `NO`

**Attribute 6:**
- [ ] Name: `externalLink1`
- [ ] Type: `String`
- [ ] Keep "Optional" CHECKED

**Attribute 7:**
- [ ] Name: `externalLink2`
- [ ] Type: `String`
- [ ] Keep "Optional" CHECKED

**Attribute 8:**
- [ ] Name: `externalLink3`
- [ ] Type: `String`
- [ ] Keep "Optional" CHECKED

### Add Relationship
- [ ] Click "Add Relationship" button
- [ ] Name: `hikeGears`
- [ ] Destination: `HikeGearEntity`
- [ ] Type: To Many (check the box)
- [ ] Inverse: `hike` (we'll set this later)
- [ ] Delete Rule: `Cascade`

### Enable CloudKit
- [ ] Check ☑️ "Used with CloudKit"

---

## ENTITY 3: HikeGearEntity

### Create Entity
- [ ] Click "+ Add Entity" button
- [ ] Rename to: `HikeGearEntity`

### Add Attributes (Click "+ " button 5 times)

**Attribute 1:**
- [ ] Name: `consumable`
- [ ] Type: `Boolean`
- [ ] Uncheck "Optional"
- [ ] Default Value: `NO`

**Attribute 2:**
- [ ] Name: `worn`
- [ ] Type: `Boolean`
- [ ] Uncheck "Optional"
- [ ] Default Value: `NO`

**Attribute 3:**
- [ ] Name: `numberUnits`
- [ ] Type: `Integer 32`
- [ ] Uncheck "Optional"
- [ ] Default Value: `1`

**Attribute 4:**
- [ ] Name: `verified`
- [ ] Type: `Boolean`
- [ ] Uncheck "Optional"
- [ ] Default Value: `NO`

**Attribute 5:**
- [ ] Name: `notes`
- [ ] Type: `String`
- [ ] Uncheck "Optional"

### Add Relationships (2 relationships)

**Relationship 1:**
- [ ] Click "Add Relationship" button
- [ ] Name: `gear`
- [ ] Destination: `GearEntity`
- [ ] Type: To One (do NOT check "To Many")
- [ ] Inverse: `hikeGears`
- [ ] Delete Rule: `Nullify`

**Relationship 2:**
- [ ] Click "Add Relationship" button
- [ ] Name: `hike`
- [ ] Destination: `HikeEntity`
- [ ] Type: To One (do NOT check "To Many")
- [ ] Inverse: `hikeGears`
- [ ] Delete Rule: `Nullify`

### Enable CloudKit
- [ ] Check ☑️ "Used with CloudKit"

---

## ENTITY 4: SettingsEntity

### Create Entity
- [ ] Click "+ Add Entity" button
- [ ] Rename to: `SettingsEntity`

### Add Attributes (Click "+ " button 2 times)

**Attribute 1:**
- [ ] Name: `imperial`
- [ ] Type: `Boolean`
- [ ] Uncheck "Optional"
- [ ] Default Value: `YES`

**Attribute 2:**
- [ ] Name: `firstTimeUser`
- [ ] Type: `Boolean`
- [ ] Uncheck "Optional"
- [ ] Default Value: `YES`

### Enable CloudKit
- [ ] Check ☑️ "Used with CloudKit"

---

## VERIFY RELATIONSHIPS (Important!)

Now go back and verify the inverse relationships are set correctly:

### Check GearEntity:
- [ ] Select `GearEntity` in left panel
- [ ] Click on `hikeGears` relationship
- [ ] In right panel, Inverse should show: `gear`
- [ ] If not, click dropdown and select `gear`

### Check HikeEntity:
- [ ] Select `HikeEntity` in left panel
- [ ] Click on `hikeGears` relationship
- [ ] In right panel, Inverse should show: `hike`
- [ ] If not, click dropdown and select `hike`

### Check HikeGearEntity:
- [ ] Select `HikeGearEntity` in left panel
- [ ] Click on `gear` relationship
- [ ] Inverse should show: `hikeGears`
- [ ] Click on `hike` relationship
- [ ] Inverse should show: `hikeGears`

---

## FINAL CHECKS

- [ ] All 4 entities exist: GearEntity, HikeEntity, HikeGearEntity, SettingsEntity
- [ ] All entities have "Used with CloudKit" checked
- [ ] All relationships have inverse relationships set
- [ ] All non-optional attributes are unchecked for "Optional"
- [ ] Default values are set where specified

---

## Save and Build

- [ ] Press Cmd+S to save
- [ ] Press Cmd+B to build project
- [ ] Check console for any errors

---

## Quick Reference

**Total Attributes:**
- GearEntity: 5 attributes, 1 relationship
- HikeEntity: 8 attributes, 1 relationship
- HikeGearEntity: 5 attributes, 2 relationships
- SettingsEntity: 2 attributes, 0 relationships

**Total: 20 attributes, 4 relationships**

---

## Troubleshooting

**Can't find "Add Entity" button?**
- Look at bottom left of the Core Data editor
- Should see "+ Add Entity" button

**Can't see Data Model Inspector?**
- Click on entity or attribute
- Look at right panel
- Click the icon that looks like a ruler (4th icon from left)

**Relationships not showing up?**
- Make sure all entities are created first
- Then add relationships
- Set inverse relationships last

**"Optional" checkbox confusing?**
- If attribute is required: UNCHECK "Optional"
- If attribute can be empty: CHECK "Optional"

---

## Time Estimate

- Creating entities: 2 minutes
- Adding attributes: 5 minutes
- Adding relationships: 3 minutes
- Setting up CloudKit: 2 minutes
- Verifying: 2 minutes

**Total: ~15 minutes**

---

## Visual Guide

```
GearEntity
├── name (String, required)
├── desc (String, required)
├── weightInGrams (Double, required, default: 0)
├── category (String, required, default: "Unknown")
├── uuid (String, required)
└── hikeGears → [HikeGearEntity] (To Many, inverse: gear)

HikeEntity
├── name (String, required)
├── desc (String, required)
├── distance (String, required)
├── location (String, required)
├── completed (Boolean, required, default: NO)
├── externalLink1 (String, optional)
├── externalLink2 (String, optional)
├── externalLink3 (String, optional)
└── hikeGears → [HikeGearEntity] (To Many, inverse: hike, Delete: Cascade)

HikeGearEntity
├── consumable (Boolean, required, default: NO)
├── worn (Boolean, required, default: NO)
├── numberUnits (Integer 32, required, default: 1)
├── verified (Boolean, required, default: NO)
├── notes (String, required)
├── gear → GearEntity (To One, inverse: hikeGears)
└── hike → HikeEntity (To One, inverse: hikeGears)

SettingsEntity
├── imperial (Boolean, required, default: YES)
└── firstTimeUser (Boolean, required, default: YES)
```

---

## Done? ✅

Once complete:
- [ ] Save the model (Cmd+S)
- [ ] Build project (Cmd+B)
- [ ] Move to STEP 2 in `FINAL_DEPLOYMENT_GUIDE.md` (Configure CloudKit)

**Good luck! You got this! 💪**
