//
//  HikeGear.swift
//  PackPlanner
//
//  Created by Kumar on 9/23/20.
//

import Foundation
import RealmSwift

class HikeGear : Object {
    @objc dynamic var gear: Gear?
    @objc dynamic var consumable: Bool = false
    @objc dynamic var worn: Bool = false
    @objc dynamic var numberUnits: Int = 1
    @objc dynamic var verified: Bool = false
    @objc dynamic var notes:String = ""
    var parentHike = LinkingObjects(fromType: Hike.self, property: "hikeGears")
}
