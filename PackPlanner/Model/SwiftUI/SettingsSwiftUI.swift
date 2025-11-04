//
//  SettingsSwiftUI.swift
//  PackPlanner
//
//  Created by Claude on SwiftUI Migration
//

import Foundation
import SwiftUI
import Combine

class SettingsSwiftUI: ObservableObject {
    @Published var imperial: Bool = true
    @Published var firstTimeUser: Bool = true
    
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

// Bridge functions for Core Data
extension SettingsSwiftUI {
    convenience init(fromCoreData settings: SettingsEntity) {
        self.init()
        self.imperial = settings.imperial
        self.firstTimeUser = settings.firstTimeUser
    }
}