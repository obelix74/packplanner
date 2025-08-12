# Stable iOS deployment target  
platform :ios, '15.0'

project 'PackPlanner.xcodeproj'

target 'PackPlanner' do
  use_frameworks!

  # Re-added Realm to fix compilation errors
  pod 'RealmSwift'
  
  # UI dependencies
  pod 'SwipeCellKit'
  pod 'ChameleonFramework/Swift', :git => 'https://github.com/wowansm/Chameleon.git', :branch => 'swift5'
  pod 'IQKeyboardManagerSwift'
  pod 'Former'
  pod 'CSV.swift', '~> 2.4.3'
end

# Simple build settings fix
post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '15.0'
    end
  end
end

