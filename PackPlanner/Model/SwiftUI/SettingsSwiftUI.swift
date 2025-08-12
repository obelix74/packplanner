//
//  SettingsSwiftUI.swift
//  PackPlanner
//
//  Created by Claude on SwiftUI Migration
//

import Foundation
import SwiftUI
import RealmSwift

@Observable
class SettingsSwiftUI {
    var imperial: Bool = true
    var firstTimeUser: Bool = true
    
    init() {}
    
    init(imperial: Bool, firstTimeUser: Bool = false) {
        self.imperial = imperial
        self.firstTimeUser = firstTimeUser
    }
    
    var weightUnit: String {
        imperial ? "lbs/oz" : "kg/g"
    }
    
    var distanceUnit: String {
        imperial ? "miles" : "kilometers"
    }
}

// Bridge functions for converting between legacy and modern models
extension SettingsSwiftUI {
    convenience init(from settings: Settings) {
        self.init()
        self.imperial = settings.imperial
        self.firstTimeUser = settings.firstTimeUser
    }
    
    func toLegacySettings() -> Settings {
        let settings = Settings()
        settings.imperial = self.imperial
        settings.firstTimeUser = self.firstTimeUser
        return settings
    }
}