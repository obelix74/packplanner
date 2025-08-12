//
//  SettingsViewController.swift
//  PackPlanner
//
//  Created by Kumar on 9/18/20.
//

import UIKit
import RealmSwift

class SettingsViewController: UIViewController {
    
    @IBOutlet weak var dismissButton: UIButton!
    let realm = try! Realm()
    var settings: Settings = SettingsManager.SINGLETON.settings
    @IBOutlet weak var unitOfWeight: UISegmentedControl!
    
    @IBOutlet weak var reviewButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let backgroundColor = UIColor.systemRed
        dismissButton.backgroundColor = backgroundColor
        dismissButton.layer.cornerRadius = 25.0
        dismissButton.tintColor = UIColor.white
        
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

    @IBAction func reviewButtonSelected(_ sender: UIButton) {
        let url = "itms-apps://itunes.apple.com/WebObjects/MZStore.woa/wa/viewContentsUserReviews?id=1534201357&onlyLatestVersion=true&pageNumber=0&sortOrdering=1&type=Purple+Software"
        if let url = URL(string: url) {
            UIApplication.shared.open(url)
        }
    }
    
    @IBAction func dismissButtonPressed(_ sender: Any) {
        dismiss(animated: true, completion: nil)
        ModalTransitionMediator.instance.sendPopoverDismissed(modelChanged: true)
    }
}
