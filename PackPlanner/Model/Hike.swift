//
//  Hike.swift
//  PackPlanner
//
//  Created by Kumar on 9/23/20.
//

import Foundation
import RealmSwift

class Hike : Object {
    let hikeGears = List<HikeGear>()
    @objc dynamic var name: String = ""
    @objc dynamic var desc: String = ""
}
