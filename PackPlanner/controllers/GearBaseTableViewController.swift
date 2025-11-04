//
//  GearBaseTableViewController.swift
//  PackPlanner
//
//  DEPRECATED: This legacy UIKit controller has been replaced by SwiftUI views
//  Kept as stub for backward compatibility
//

import UIKit
import CoreData

class GearBaseTableViewController: UITableViewController {
    var gearBrain: GearBrainCD?

    override func viewDidLoad() {
        super.viewDidLoad()
        print("⚠️ GearBaseTableViewController is deprecated. Use SwiftUI views instead.")
    }

    func loadGear() {
        // Stub implementation
    }
}
