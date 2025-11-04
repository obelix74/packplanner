//
//  AddGearViewController.swift
//  PackPlanner
//
//  DEPRECATED: This legacy UIKit controller has been replaced by AddGearViewBridge (SwiftUI)
//  Kept as stub for backward compatibility with storyboard references
//

import UIKit
import Former
import CoreData

class AddGearViewController: FormViewController {

    @IBOutlet weak var saveButton: UIButton!

    // Legacy properties for backward compatibility
    var name: String?
    var desc: String?
    var weight: Double?
    var category: String?
    var existingGearCoreData: GearEntity?

    override func viewDidLoad() {
        super.viewDidLoad()
        print("⚠️ AddGearViewController is deprecated. Use AddGearViewBridge instead.")
    }
}
