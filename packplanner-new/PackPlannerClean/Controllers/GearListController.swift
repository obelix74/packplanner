//
//  ItemViewController.swift
//  PackPlanner
//
//  Created by Kumar on 9/18/20.
//

import UIKit
import RealmSwift
import ChameleonFramework
import SwipeCellKit
import SwiftUI

class GearListController: GearBaseTableViewController, ModalTransitionListener, SwipeTableViewCellDelegate {
    
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var addButton: UIBarButtonItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.rowHeight = 65
        searchBar.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        searchBar.barTintColor = .flatWhite()
        addButton.tintColor = .white
    }
    
    
    // MARK: - Table view data source
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "gearCell", for: indexPath) as! GearTableViewCell
        cell.delegate = self
        
        if (gearBrain!.isEmpty()) {
            cell.nameLabel.text = "No gear found"
        } else {
            cell.existingGear = gearBrain?.getGear(indexPath: indexPath)
            cell.accessoryType = .disclosureIndicator;
        }
        return cell
    }
    
    //MARK: - Tableview delegate methods
    @IBAction func showSettings(_ sender: UIBarButtonItem) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let settingsController = storyboard.instantiateViewController(withIdentifier: "SettingsViewController")
        present(settingsController, animated: true)
    }
    
    @IBAction func addButtonPressed(_ sender: UIBarButtonItem) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let addGearController = storyboard.instantiateViewController(withIdentifier: "AddGearViewController")
        navigationController?.pushViewController(addGearController, animated: true)
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let gear = gearBrain?.getGear(indexPath: indexPath) {
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let editGearController = storyboard.instantiateViewController(withIdentifier: "AddGearViewController") as! AddGearViewController
            editGearController.existingGear = gear
            navigationController?.pushViewController(editGearController, animated: true)
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == "showAddGear" && tableView.indexPathForSelectedRow != nil) {
            let destinationVC = segue.destination as! AddGearViewController
            if let indexPath = tableView.indexPathForSelectedRow {
                destinationVC.existingGear = gearBrain?.getGear(indexPath: indexPath)
            }
        }
    }
    
    //MARK: Swipe
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath, for orientation: SwipeActionsOrientation) -> [SwipeAction]? {        
        if (orientation == .right) {
            let deleteAction = SwipeAction(style: .destructive, title: "Delete") { action, indexPath in
                self.updateModel(at: indexPath)
                action.fulfill(with: .delete)
            }
            
            // customize the action appearance
            deleteAction.image = UIImage(systemName: "trash")
            
            return [deleteAction]
        }
        else {
            let copyAction = SwipeAction(style: .default, title: "Copy") { action, indexPath in
                let gear = self.gearBrain?.getGear(indexPath: indexPath)
                GearBrain.copyGear(gear: gear!)
                self.loadGear()
            }
            copyAction.hidesWhenSelected = true
            copyAction.image = UIImage(systemName: "doc")
            
            return [copyAction]
        }
    }
    
    func updateModel(at indexPath: IndexPath) {
        print("UpdateModel called")
        let refreshAlert = UIAlertController(title: "Refresh", message: "Are you sure you want to delete? This gear will be removed from all hikes.", preferredStyle: UIAlertController.Style.alert)
        
        refreshAlert.addAction(UIAlertAction(title: "Delete", style: .default, handler: { (action: UIAlertAction!) in
            self.gearBrain?.deleteGearAt(indexPath: indexPath)
            self.loadGear()
        }))
        
        refreshAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action: UIAlertAction!) in
            self.tableView.reloadData()
        }))
        
        present(refreshAlert, animated: true, completion: nil)
    }
    
    //MARK: - settings modal
    func popoverDismissed() {
        tableView.reloadData()
    }
}


