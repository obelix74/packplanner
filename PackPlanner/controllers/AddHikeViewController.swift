//
//  AddHikeViewController.swift
//  PackPlanner
//
//  DEPRECATED: This legacy UIKit controller has been replaced by AddHikeViewBridge (SwiftUI)
//  Kept as stub for backward compatibility with storyboard references
//

import UIKit

class AddHikeViewController: UIViewController {

    // Legacy outlets kept for storyboard compatibility
    @IBOutlet weak var nameField: UITextField!
    @IBOutlet weak var descriptionField: UITextField!
    @IBOutlet weak var saveButton: UIBarButtonItem!
    @IBOutlet weak var completedSwitch: UISwitch!
    @IBOutlet weak var locationField: UITextField!
    @IBOutlet weak var distanceField: UITextField!
    @IBOutlet weak var url1Field: UITextField!
    @IBOutlet weak var url2Field: UITextField!
    @IBOutlet weak var url3Field: UITextField!

    override func viewDidLoad() {
        super.viewDidLoad()

        // This controller is deprecated - use SwiftUI AddHikeViewBridge instead
        print("⚠️ AddHikeViewController is deprecated. Use AddHikeViewBridge instead.")

        // Show alert to user
        let alert = UIAlertController(
            title: "Feature Unavailable",
            message: "This feature is being updated. Please use the new interface.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default) { [weak self] _ in
            self?.dismiss(animated: true)
        })
        present(alert, animated: true)
    }
}
