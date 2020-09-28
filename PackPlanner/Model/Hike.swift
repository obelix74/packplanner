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
    @objc dynamic var distance: String = ""
    @objc dynamic var location: String = ""
    @objc dynamic var completed: Bool = false
    @objc dynamic var externalLink1: String?
    @objc dynamic var externalLink2: String?
    @objc dynamic var externalLink3: String?
}
