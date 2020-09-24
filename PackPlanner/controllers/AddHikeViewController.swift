//
//  AddHikeViewController.swift
//  PackPlanner
//
//  Created by Kumar on 9/23/20.
//

import UIKit
import ChameleonFramework
import RealmSwift

class AddHikeViewController: BaseViewController {

    @IBOutlet weak var nameField: UITextField!
    @IBOutlet weak var descriptionField: UITextField!
    @IBOutlet weak var saveButton: UIBarButtonItem!
    
    let realm = try! Realm()
    var hike : Hike?

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        saveButton.tintColor = .flatWhite()
        self.title = self.hike?.name ?? "Add hike"
        
        if (self.hike != nil) {
            self.nameField.text = self.hike?.name
            self.descriptionField.text = self.hike?.desc
        }
    }

    @IBAction func saveButtonPressed(_ sender: UIBarButtonItem) {
        let name = nameField.text
        let desc = descriptionField.text
        
        if (name!.isEmpty) {
            showAlert(name: "Name")
            return
        }
        
        let existing = self.hike != nil
        
        do {
            try realm.write {
                if (self.hike != nil) {
                    self.hike!.name = name!
                    self.hike!.desc = desc!
                } else {
                    self.hike = Hike()
                    self.hike!.name = name!
                    self.hike!.desc = desc!
                    self.realm.add(hike!)
                }
            }
            
        } catch {
            print("Error saving new hike\(error)")
        }
        
        if (existing) {
            _ = navigationController?.popViewController(animated: true)
        }
        else {
            performSegue(withIdentifier: "showHike", sender: self)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == "showHike") {
            let destinationVC = segue.destination as! HikeDetailViewController
            destinationVC.existingHike = self.hike 
        }
    }
    
    func showAlert(name: String) {
        let alert = UIAlertController(title: "Missing input", message: "\(name) is required", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Dismiss", style: .cancel, handler: nil))
        
        self.present(alert, animated: true)
    }
}
