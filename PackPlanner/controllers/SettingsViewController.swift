//
//  SettingsViewController.swift
//  PackPlanner
//
//  Created by Kumar on 9/18/20.
//

import UIKit
import ChameleonFramework
import RealmSwift

class SettingsViewController: UIViewController {
    
    @IBOutlet weak var saveButton: UIButton!
    let realm = try! Realm()
    var settings: Settings = SettingsManager.SINGLETON.settings
    @IBOutlet weak var unitOfWeight: UISegmentedControl!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let backgroundColor = UIColor.flatRedDark()
        saveButton.backgroundColor = backgroundColor
        saveButton.layer.cornerRadius = 25.0
        saveButton.tintColor = ContrastColorOf(backgroundColor, returnFlat: true)
        
        if(settings.imperial) {
            unitOfWeight.selectedSegmentIndex = 0
        } else {
            unitOfWeight.selectedSegmentIndex = 1
        }
    }
    
    
    @IBAction func weightSettingsChanged(_ segment: UISegmentedControl) {
        if let title = segment.titleForSegment(at: segment.selectedSegmentIndex) {
            do {
                try realm.write {
                    if title.hasPrefix("Imperial") {
                        print("Updating settings to Imperial")
                        settings.imperial = true
                    } else {
                        print("Updating settings to Metric")
                        settings.imperial = false
                    }
                }
            } catch {
                print("Error updating Settings \(error)")
            }
        }
    }
    
    @IBAction func doneButtonSelected(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
}
