//
//  AddGearToHikeTableViewController.swift
//  PackPlanner
//
//  Created by Kumar on 9/23/20.
//

import UIKit
import RealmSwift

class AddGearToHikeTableViewController: GearBaseTableViewController {
    
    @IBOutlet weak var saveButton: UIBarButtonItem!
    
    var hike : Hike?
    
    var gearSelected : [Gear:Bool] = [:]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.allowsMultipleSelection = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if (hike != nil) {
            self.title = "Adding gear to \(hike!.name)"
        }
        saveButton.tintColor = UIColor.white
    }
    
    @IBAction func saveButtonSelected(_ sender: UIBarButtonItem) {
        let selectedRows = tableView.indexPathsForSelectedRows
        selectedRows?.forEach({ (indexPath) in
            let gear = gearBrain?.getGear(indexPath: indexPath)
            print("Adding gear \(gear!.name)")
            HikeBrain.createHikeGear(gear: gear!, hike: hike!)
        })
        
        performSegue(withIdentifier: "showHikeDetail", sender: self)
    }
    
    override func getGearBrain(_ search: String) -> GearBrain{
        let gearBrain = GearBrain.getFilteredGearsForExistingHike(hike: hike!)
        gearBrain.gears.forEach { (gear) in
            self.gearSelected[gear] = false 
        }
        return gearBrain
    }
    
    override func getNoGearMessage() -> [String:String]{
        var dict : [String:String] = [:]
        dict["title"] = "No gear found"
        dict["message"] = "Did you already add all existing gear to this hike?"
        return dict
    }
    
    override func shouldShowAlert() -> Bool {
        return true 
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == "showHikeDetail") {
            let destinationVC = segue.destination as! HikeDetailViewController
            destinationVC.existingHike = hike
        }
    }
    
    // MARK: - Table view data source
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "gearCell", for: indexPath) as! GearTableViewCell
        
        if (gearBrain!.isEmpty()) {
            cell.textLabel?.text = "No gears found"
        } else {
            cell.existingGear = gearBrain?.getGear(indexPath: indexPath)
            if (self.gearSelected[cell.existingGear!]!) {
                cell.accessoryType = .checkmark
            }
            else {
                cell.accessoryType = .none
            }
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath)!
        let gear = self.gearBrain!.getGear(indexPath: indexPath)
        self.gearSelected[gear!] = true
        cell.accessoryType = .checkmark
    }
    
    override func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath)!
        let gear = self.gearBrain!.getGear(indexPath: indexPath)
        self.gearSelected[gear!] = false
        cell.accessoryType = .none
    }
}
