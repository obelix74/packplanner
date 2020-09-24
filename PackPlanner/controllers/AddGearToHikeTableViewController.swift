//
//  AddGearToHikeTableViewController.swift
//  PackPlanner
//
//  Created by Kumar on 9/23/20.
//

import UIKit
import ChameleonFramework
import RealmSwift

class AddGearToHikeTableViewController: GearBaseTableViewController {
    
    @IBOutlet weak var saveButton: UIBarButtonItem!
    
    var hike : Hike? {
        didSet {
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.allowsMultipleSelection = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if (hike != nil) {
            self.title = "Adding gear to \(hike!.name)"
        }
        saveButton.tintColor = .flatWhite()
    }
    
    @IBAction func saveButtonSelected(_ sender: UIBarButtonItem) {
        let selectedRows = tableView.indexPathsForSelectedRows
        selectedRows?.forEach({ (indexPath) in
            let gear = gearBrain?.getGear(indexPath: indexPath)
            print("Adding gear \(gear!.name)")
            GearBrain.createHikeGear(gear: gear!, hike: hike!)
        })
        
        performSegue(withIdentifier: "showHikeDetail", sender: self)
    }
    
    override func getGearBrain(_ search: String) -> GearBrain{
        return GearBrain.getFilteredGearsForExistingHike(hike: hike!)
    }
    
    override func getNoGearMessage() -> [String:String]{
        var dict : [String:String] = [:]
        dict["title"] = "No gear found"
        dict["message"] = "Did you already add all existing gear to this hike?"
        return dict
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == "showHikeDetail") {
            let destinationVC = segue.destination as! HikeDetailViewController
            destinationVC.existingHike = hike
        }
    }
    
    // MARK: - Table view data source
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "gearCell", for: indexPath) as! AddGearToHikeTableViewCell
        
        if (gearBrain!.isEmpty()) {
            cell.textLabel?.text = "No gears found"
        } else {
            cell.gear = gearBrain?.getGear(indexPath: indexPath)
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath)!
        cell.accessoryType = .checkmark
    }
    
    override func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath)!
        cell.accessoryType = .none
    }
}
