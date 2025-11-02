//
//  AddGearToHikeTableViewController.swift
//  PackPlanner
//
//  Created by Kumar on 9/23/20.
//  Core Data version
//

import UIKit
import CoreData

class AddGearToHikeTableViewController: GearBaseTableViewController {

    @IBOutlet weak var saveButton: UIBarButtonItem!

    var hike : HikeEntity?

    var gearSelected : [NSManagedObjectID:Bool] = [:]
    
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
        guard let hike = hike else { return }

        let selectedRows = tableView.indexPathsForSelectedRows
        selectedRows?.forEach({ (indexPath) in
            if let gear = gearBrain?.getGear(indexPath: indexPath) {
                HikeBrainCD.createHikeGear(gear: gear, hike: hike)
            }
        })

        performSegue(withIdentifier: "showHikeDetail", sender: self)
    }

    override func getGearBrain(_ search: String) -> GearBrainCD{
        guard let hike = hike else { return GearBrainCD([]) }
        let gearBrain = GearBrainCD.getFilteredGearsForExistingHike(hike: hike)
        gearBrain.gears.forEach { (gear) in
            self.gearSelected[gear.objectID] = false
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
            // TODO: Update HikeDetailViewController to support Core Data
            // Temporarily disabled pending full migration
            print("⚠️ showHikeDetail segue needs HikeDetailViewController Core Data update")
        }
    }
    
    // MARK: - Table view data source
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "gearCell", for: indexPath) as! GearTableViewCell

        if (gearBrain!.isEmpty()) {
            cell.nameLabel.text = "No gears found"
        } else {
            let gear = gearBrain?.getGear(indexPath: indexPath)
            // Manually set cell labels since GearTableViewCell doesn't have Core Data property yet
            cell.nameLabel.text = gear?.name ?? ""
            cell.weightLabel.text = gear?.weightString(imperial: SettingsManagerCD.SINGLETON.settings.imperial) ?? ""

            if let gear = gear, let isSelected = self.gearSelected[gear.objectID], isSelected {
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
        if let gear = self.gearBrain?.getGear(indexPath: indexPath) {
            self.gearSelected[gear.objectID] = true
            cell.accessoryType = .checkmark
        }
    }

    override func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath)!
        if let gear = self.gearBrain?.getGear(indexPath: indexPath) {
            self.gearSelected[gear.objectID] = false
            cell.accessoryType = .none
        }
    }
}
