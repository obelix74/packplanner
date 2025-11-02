# CloudKit Configuration Guide

This guide walks you through enabling and configuring CloudKit for PackPlanner.

## Prerequisites

- Apple Developer Account (required for CloudKit)
- Xcode 12 or later
- Completed Core Data model setup (see COREDATA_SETUP_INSTRUCTIONS.md)

---

## Step 1: Enable iCloud Capability

1. Open `PackPlanner.xcworkspace` in Xcode
2. Select the **PackPlanner** project in Project Navigator
3. Select the **PackPlanner** target
4. Go to the **Signing & Capabilities** tab
5. Click the **+ Capability** button
6. Search for and add **iCloud**

---

## Step 2: Configure iCloud Services

After adding iCloud capability, you'll see iCloud settings:

1. Check **CloudKit**
2. Under "Containers", you should see a default container
3. Note the container identifier (e.g., `iCloud.com.anand.PackPlanner`)
4. If you need to change it, click the **+** button to add a custom container

**Important:** The container identifier in `CoreDataStack.swift` must match what you configure here.

Current setting in CoreDataStack.swift:
```swift
containerIdentifier: "iCloud.com.anand.PackPlanner"
```

Update this if your container identifier is different.

---

## Step 3: Enable Background Modes

CloudKit needs background modes for sync:

1. In the **Signing & Capabilities** tab
2. Click **+ Capability**
3. Add **Background Modes**
4. Check the following:
   - ☑️ **Remote notifications** (for CloudKit sync notifications)

---

## Step 4: Configure Bundle Identifier

Ensure your bundle identifier matches your Apple Developer account:

1. In **General** tab
2. Verify **Bundle Identifier** (e.g., `com.anand.PackPlanner`)
3. This should match your provisioning profile

---

## Step 5: Update Info.plist (Optional Privacy Descriptions)

While not strictly required, it's good practice to add usage descriptions:

1. Open `Info.plist`
2. Add the following keys if prompting users about iCloud:

```xml
<key>NSUbiquitousContainersUsageDescription</key>
<string>PackPlanner uses iCloud to sync your gear and hikes across all your devices.</string>
```

---

## Step 6: Verify CloudKit Dashboard

Check your CloudKit configuration in the CloudKit Dashboard:

1. Go to [https://icloud.developer.apple.com/dashboard](https://icloud.developer.apple.com/dashboard)
2. Sign in with your Apple Developer account
3. Select your app
4. Select the CloudKit container
5. You should see:
   - **Schema**: After first launch, Core Data will create schema automatically
   - **Data**: Empty initially, will populate as you use the app

---

## Step 7: Test CloudKit Status

Build and run the app. Check the console for CloudKit status messages:

```
✅ Core Data loaded successfully
✅ iCloud is available
```

If you see errors:
- `⚠️ No iCloud account` → Sign in to iCloud in Settings app
- `⚠️ iCloud is restricted` → Check device restrictions
- `⚠️ Network unavailable` → Check internet connection

---

## Step 8: Testing iCloud Sync

### Single Device Testing:

1. Launch the app on a device/simulator
2. Check console for: `✅ Core Data loaded successfully`
3. Create some test data (gears, hikes)
4. Check CloudKit Dashboard to see data synced

### Multi-Device Testing:

1. Sign in with the same Apple ID on two devices
2. Launch app on Device 1
3. Create test data
4. Wait a few seconds for sync
5. Launch app on Device 2
6. Verify data appears automatically

**Note:** Simulator testing with iCloud can be unreliable. Test on real devices when possible.

---

## Troubleshooting

### "No iCloud account" error

**Solution:** Go to Settings → Sign in to iCloud

### Data not syncing

**Checklist:**
- ✓ Same Apple ID on both devices
- ✓ iCloud enabled in Settings
- ✓ Internet connection active
- ✓ Wait 30-60 seconds for sync
- ✓ Check CloudKit Dashboard for data

### "Development environment" warning

This is normal during development. When you submit to App Store:
1. In CloudKit Dashboard, deploy schema to Production
2. App Store builds will use Production environment

### Schema errors in CloudKit Dashboard

**Solution:**
1. Delete the app from device/simulator
2. Reset CloudKit Development Environment:
   - CloudKit Dashboard → Schema → Development → Reset
3. Rebuild and run the app
4. Schema will regenerate automatically

---

## Core Data + CloudKit Schema Generation

Core Data automatically generates CloudKit schema when you:

1. Mark entities as "Used with CloudKit" in the data model editor
2. Launch the app for the first time with CloudKit enabled
3. Save data to Core Data

**Viewing the Schema:**
1. Go to CloudKit Dashboard
2. Select your container
3. Click "Schema" → "Development"
4. You should see:
   - `CD_GearEntity`
   - `CD_HikeEntity`
   - `CD_HikeGearEntity`
   - `CD_SettingsEntity`

(Core Data prefixes entity names with `CD_` in CloudKit)

---

## Best Practices

### 1. Development vs Production

- **Development:** Use during development and testing
- **Production:** Deploy schema to production before App Store release

### 2. Schema Changes

⚠️ **WARNING:** CloudKit schema changes are permanent in Production!

- Test all schema changes in Development first
- Be extremely careful adding/removing fields in Production
- CloudKit supports adding fields, but removing them is destructive

### 3. Quota Limits

CloudKit has generous limits:
- **Free tier per user:**
  - 1GB storage
  - 10GB transfer per month
  - 40 requests per second

For most users, this is more than enough.

### 4. Error Handling

The app includes error handling for:
- No iCloud account
- Network failures
- Quota exceeded
- Account restrictions

Users will see appropriate messages and can continue using the app locally.

---

## Deployment Checklist

Before releasing to App Store:

- [ ] Test multi-device sync thoroughly
- [ ] Deploy CloudKit schema to Production environment
- [ ] Update version number
- [ ] Test on iOS 13+ devices (minimum supported version)
- [ ] Verify background sync works
- [ ] Check CloudKit quota won't be exceeded for your user base
- [ ] Add CloudKit status monitoring in production

---

## Additional Resources

- [Apple CloudKit Documentation](https://developer.apple.com/documentation/cloudkit)
- [Core Data + CloudKit Guide](https://developer.apple.com/documentation/coredata/mirroring_a_core_data_store_with_cloudkit)
- [CloudKit Dashboard](https://icloud.developer.apple.com/dashboard)

---

## Next Steps

After completing CloudKit configuration:

1. Run the migration to convert existing Realm data to Core Data
2. Test the app with both Realm and Core Data
3. Gradually update controllers to use Core Data
4. Test CloudKit sync across devices
5. Monitor sync performance and errors
