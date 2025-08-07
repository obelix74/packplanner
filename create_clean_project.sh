#!/bin/bash

# Create a clean PackPlanner project
echo "Creating clean PackPlanner project..."

# Remove existing clean project if it exists
rm -rf PackPlannerClean

# Create new project directory structure
mkdir -p PackPlannerClean
cd PackPlannerClean

# Create the iOS app project using xcodeproj command line tool
# Since we don't have xcodeproj generator, we'll copy the working structure
# and clean it up

echo "Copying source files..."
mkdir -p PackPlannerClean/{Controllers,Model,Views,Helpers}

# Copy all source files (using correct relative paths)
cp -f PackPlanner/controllers/*.swift PackPlannerClean/Controllers/ 2>/dev/null || true
cp -f PackPlanner/Model/*.swift PackPlannerClean/Model/ 2>/dev/null || true
cp -f PackPlanner/Views/*.swift PackPlannerClean/Views/ 2>/dev/null || true
cp -f PackPlanner/Helpers/*.swift PackPlannerClean/Helpers/ 2>/dev/null || true

# Copy essential files
cp -f PackPlanner/AppDelegate.swift PackPlannerClean/ 2>/dev/null || true
cp -f PackPlanner/SceneDelegate.swift PackPlannerClean/ 2>/dev/null || true
cp -f PackPlanner/Info.plist PackPlannerClean/ 2>/dev/null || true
cp -R PackPlanner/Assets.xcassets PackPlannerClean/ 2>/dev/null || true
cp -R PackPlanner/Base.lproj PackPlannerClean/ 2>/dev/null || true

# Copy main storyboard if not in Base.lproj
cp -R PackPlanner/Views/Base.lproj PackPlannerClean/Views/ 2>/dev/null || true

# Create a clean Xcode project by copying the existing one and cleaning it
cp -R PackPlanner.xcodeproj PackPlannerClean.xcodeproj 2>/dev/null || true

echo "Project structure created. Now run 'pod install' in the PackPlannerClean directory."