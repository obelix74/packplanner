//
//  AddHikeViewController.swift
//  PackPlanner
//
//  Created by Kumar on 9/23/20.
//

import UIKit
import RealmSwift

class AddHikeViewController: BaseViewController {

    @IBOutlet weak var nameField: UITextField!
    @IBOutlet weak var descriptionField: UITextField!
    @IBOutlet weak var saveButton: UIBarButtonItem!
    @IBOutlet weak var completedSwitch: UISwitch!
    @IBOutlet weak var locationField: UITextField!
    @IBOutlet weak var distanceField: UITextField!
    @IBOutlet weak var url1Field: UITextField!
    @IBOutlet weak var url2Field: UITextField!
    @IBOutlet weak var url3Field: UITextField!
    
    private var realm: Realm!
    var hike : Hike?
    var delegate : RefreshProtocol?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Initialize Realm safely
        do {
            realm = try Realm()
        } catch {
            print("Critical: Failed to initialize Realm in AddHikeViewController: \(error)")
            // Show user-friendly error and disable functionality
            let alert = UIAlertController(
                title: "Database Error", 
                message: "Unable to save hikes. Please restart the app.", 
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
            // Disable save functionality if realm is not available
            saveButton.isEnabled = false
            return
        }
        
        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        saveButton.tintColor = UIColor.white
        self.title = self.hike?.name ?? "Add hike"
        
        if (self.hike != nil) {
            self.nameField.text = self.hike?.name
            self.descriptionField.text = self.hike?.desc
            self.completedSwitch.isOn = self.hike!.completed
            self.locationField.text = self.hike?.location
            self.distanceField.text = self.hike?.distance
            self.url1Field.text = self.hike?.externalLink1
            self.url2Field.text = self.hike?.externalLink2
            self.url3Field.text = self.hike?.externalLink3
        }
    }

    @IBAction func saveButtonPressed(_ sender: UIBarButtonItem) {
        let name = nameField.text
        let desc = descriptionField.text
        let completed = self.completedSwitch.isOn
        let location = self.locationField.text
        let distance = self.distanceField.text
        let url1 = self.url1Field.text
        let url2 = self.url2Field.text
        let url3 = self.url3Field.text
        
        if (name!.isEmpty) {
            showAlert(name: "Name")
            return
        }
        
        let existing = self.hike != nil
        
        do {
            try realm.write {
                if (self.hike == nil) {
                    self.hike = Hike()
                }
                self.hike!.name = name!
                self.hike!.desc = desc ?? ""
                self.hike!.completed = completed
                self.hike!.location = location ?? ""
                self.hike!.distance = distance ?? ""
                self.hike!.externalLink1 = url1 ?? ""
                self.hike!.externalLink2 = url2 ?? ""
                self.hike!.externalLink3 = url3 ?? ""
                
                if (!existing) {
                    self.realm.add(hike!)
                }
            }
            
        } catch {
            print("Error saving new hike\(error)")
        }
        
        if (existing) {
            _ = navigationController?.popViewController(animated: true)
            if (self.delegate != nil) {
                self.delegate?.refresh(at: nil)
            }
        }
        else {
            performSegue(withIdentifier: "addGearToHike", sender: self)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == "showHike") {
            let destinationVC = segue.destination as! HikeDetailViewController
            destinationVC.existingHike = self.hike 
        }
        else if (segue.identifier == "addGearToHike") {
            let destinationVC = segue.destination as! AddGearToHikeTableViewController
            destinationVC.hike = self.hike 
        }
    }
    
    func showAlert(name: String) {
        let alert = UIAlertController(title: "Missing input", message: "\(name) is required", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Dismiss", style: .cancel, handler: nil))
        
        self.present(alert, animated: true)
    }
}
