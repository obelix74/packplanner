//
//  SettingsManager.swift
//  PackPlanner
//
//  Created by Kumar on 9/20/20.
//

import Foundation
import RealmSwift

class SettingsManager {
    
    let realm = try! Realm()
    static let SINGLETON = SettingsManager()
    var settings: Settings = Settings()
    
    private init() {
        let results : Results<Settings> = realm.objects(Settings.self)
        if (results.count == 0) {
            do {
                try realm.write {
                    realm.add(settings)
                }
            } catch {
                print("Error creating settings \(error)")
            }
        } else {
            self.settings = results.first!
        }
    }
    
    func weightUnitString() -> String {
        return self.settings.imperial ? "(Oz)" : "(Grams)"
    }
}
