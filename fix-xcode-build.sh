#!/bin/bash

echo "🔧 Fixing Xcode build issues..."

# Clean all derived data
echo "Cleaning derived data..."
rm -rf ~/Library/Developer/Xcode/DerivedData/PackPlanner*

# Clean project
echo "Cleaning project..."
xcodebuild -workspace PackPlanner.xcworkspace -scheme PackPlanner clean

# Rebuild pods
echo "Rebuilding CocoaPods..."
pod install

# Build project
echo "Building project..."
xcodebuild -workspace PackPlanner.xcworkspace -scheme PackPlanner -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=18.5' build

echo "✅ Build fix complete!"