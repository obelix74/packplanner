//
//  HikeGear.swift
//  PackPlanner
//
//  Created by Kumar on 9/23/20.
//

import Foundation
import RealmSwift

class HikeGear : Object {
    // We need only one gear, but Realm expects this to be a list.
    let gear = List<Gear> ()
    @objc dynamic var consumable: Bool = false
    @objc dynamic var worn: Bool = false
    @objc dynamic var numberUnits: Int = 1
    var parentHike = LinkingObjects(fromType: Hike.self, property: "hikeGears")
}
