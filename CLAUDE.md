# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

PackPlanner is an iOS hiking and gear planning application built with UIKit, targeting iOS 13+. The app helps hikers plan their gear for trips, track weight distributions, and manage hiking inventories.

## Build & Development Commands

**Prerequisites:**
- Xcode 12+ 
- CocoaPods installed (`gem install cocoapods`)

**Setup:**
```bash
pod install
```

**Build & Run:**
- Open `PackPlanner.xcworkspace` (not .xcodeproj) in Xcode
- Build using Xcode's build button or `Cmd+B`
- Run on simulator or device using `Cmd+R`

**Dependencies managed via CocoaPods:**
- RealmSwift (database)
- SwipeCellKit (table cell swipe actions)
- ChameleonFramework/Swift (color utilities)
- IQKeyboardManagerSwift (keyboard handling)
- Former (form building)
- CSV.swift (data export)

## Architecture

**Pattern:** Model-View-Controller with "Brain" service layer

**Core Architecture:**
- **Models** (`/Model/`): Realm objects for data persistence
  - `Gear`: Individual gear items with weight, category, description
  - `Hike`: Hiking trips with metadata (name, location, distance, completion status)
  - `HikeGear`: Join table linking gears to specific hikes with quantities and flags
  - `Settings`: App-wide preferences (imperial/metric units, first-time user flag)

- **Brain Classes** (Service Layer):
  - `GearBrain`: Business logic for gear management, filtering, CRUD operations
  - `HikeBrain`: Weight calculations, gear categorization for hikes, distribution analysis
  - `SettingsManager`: Singleton managing app settings with Realm persistence

- **Controllers** (`/controllers/`): UITableViewController and UIViewController subclasses
  - `HikeListController`: Main screen showing all hikes with search/swipe actions
  - `HikeDetailViewController`: Displays gear for specific hike with weight calculations
  - `AddGearViewController`/`AddHikeViewController`: Form-based creation screens using Former
  - `GearListController`: Manages gear inventory

- **Views** (`/Views/`): Custom UITableViewCell subclasses and UI helpers
  - Custom cells for hikes, gear, and hike-gear associations
  - Input accessory views and transition listeners

**Key Data Flow:**
1. Realm objects (Models) store data
2. Brain classes provide business logic and weight calculations
3. Controllers manage UI state and user interactions
4. Views display data with custom cells

**Weight Calculation System:**
- Base Weight: Non-consumable, non-worn gear
- Consumable Weight: Food, toiletries, etc.
- Worn Weight: Items worn on body
- Total Weight: Sum of all categories
- All calculations handled in `HikeBrain` with metric/imperial conversion

**Critical Business Logic:**
- Weight conversions between grams/ounces handled in `Gear` model
- Category-based gear organization throughout app
- Export functionality generates CSV with gear lists and weight summaries
- Hike copying creates deep copies of all associated gear relationships

## Database Schema (Realm)

**Legacy Models (UIKit):**
- `Hike` ← one-to-many → `HikeGear` ← many-to-one → `Gear`
- Each HikeGear links a Gear to a Hike with quantity and boolean flags (worn, consumable, verified)
- Uses Realm's legacy `@objc dynamic` syntax

**Modern Models (SwiftUI - iOS 15+):**
- Located in `PackPlanner/Model/SwiftUI/`
- `HikeSwiftUI`, `GearSwiftUI`, `HikeGearSwiftUI`, `SettingsSwiftUI`
- Uses `@Observable` macro for reactive SwiftUI integration
- `DataService.swift` provides centralized CRUD operations
- Bridge functions convert between legacy and modern models

## SwiftUI Integration

**Modern Views:** Located in `PackPlanner/Views/SwiftUI/`
- `AddGearView.swift` - Native SwiftUI forms (replaces Former library)
- `GearListView.swift` - Category-organized list with native swipe actions
- `HikeListView.swift` - Search-enabled hike planning interface
- `HikeDetailView.swift` - Comprehensive gear management with toggles
- `SettingsView.swift` - Modern settings with unit preferences

**Bridge Layer:** `SwiftUIBridge.swift`
- `SwiftUIMigrationHelper` - Factory methods for gradual UIKit→SwiftUI transition
- Feature flags control which views use SwiftUI vs UIKit
- `UIHostingController` integration for seamless embedding

**Key Integration Points:**
- Modified UIKit controllers use `SwiftUIMigrationHelper.shared.createXXXViewController()` 
- Settings: `SettingsManagerSwiftUI.shared` for reactive settings management
- Data: `DataService.shared` for all CRUD operations
- Testing: `SwiftUIIntegrationTestHelper` validates functionality

**Dependencies Eliminated:**
- SwipeCellKit → Native `.swipeActions`
- Former → Native SwiftUI `Form` controls  
- ChameleonFramework manual styling → Native SwiftUI modifiers

**Migration Status:** Tracked via `MigrationStatusTracker.shared`