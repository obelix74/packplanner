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

class GearListController: GearBaseTableViewController, ModalTransitionListener, SwipeTableViewCellDelegate {
    
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var addButton: UIBarButtonItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.rowHeight = 100.0
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
        
        if (gearBrain?.gears?.count == 0) {
            cell.nameLabel.text = "No gear found"
        } else {
            let section = indexPath.section
            let category = gearBrain?.categoriesSorted?[section]
            if (category != nil) {
                let gearsInSection = gearBrain?.categoryMap![category!]
                let gear = gearsInSection![indexPath.row]
                cell.existingGear = gear
                cell.accessoryType = .disclosureIndicator;
            }
            
        }
        return cell
    }
    
    
    @IBAction func showSettings(_ sender: UIBarButtonItem) {
        ModalTransitionMediator.instance.setListener(listener: self)
        performSegue(withIdentifier: "showSettings", sender: self)
        
    }
    
    @IBAction func addButtonPressed(_ sender: UIBarButtonItem) {
        performSegue(withIdentifier: "showAddGear", sender: self)
    }
        
    //MARK: - Tableview delegate methods
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        performSegue(withIdentifier: "showAddGear", sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == "showAddGear" && tableView.indexPathForSelectedRow != nil) {
            let destinationVC = segue.destination as! AddGearViewController
            if let indexPath = tableView.indexPathForSelectedRow {
                
                let section = indexPath.section
                let category = gearBrain?.categoriesSorted?[section]
                if (category != nil) {
                    let gearsInSection = gearBrain?.categoryMap![category!]
                    let gear = gearsInSection![indexPath.row]
                    destinationVC.existingGear = gear
                }
            }
        }
    }
    
    //MARK: Swipe
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath, for orientation: SwipeActionsOrientation) -> [SwipeAction]? {
        guard orientation == .right else { return nil }
        
        let deleteAction = SwipeAction(style: .destructive, title: "Delete") { action, indexPath in
            self.updateModel(at: indexPath)
            action.fulfill(with: .delete)
        }
        
        // customize the action appearance
        deleteAction.image = UIImage(named: "delete-icon")
        
        return [deleteAction]
    }
    
    func updateModel(at indexPath: IndexPath) {
        print("UpdateModel called")
        let refreshAlert = UIAlertController(title: "Refresh", message: "Are you sure you want to delete? This gear will be removed from all hikes.", preferredStyle: UIAlertController.Style.alert)
        
        refreshAlert.addAction(UIAlertAction(title: "Delete", style: .default, handler: { (action: UIAlertAction!) in
            let section = indexPath.section
            if let category = self.gearBrain?.categoriesSorted?[section] {
                if let gears = self.gearBrain?.categoryMap?[category] {
                    do {
                        try self.gearBrain?.realm.write {
                            self.gearBrain?.realm.delete(gears[indexPath.row])
                            self.loadGear()
                        }
                    }catch {
                        print("Error deleting gear \(error)")
                    }
                }
            }
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


