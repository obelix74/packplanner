//
//  ItemViewController.swift
//  PackPlanner
//
//  Created by Kumar on 9/18/20.
//

import UIKit
import RealmSwift
import SwipeCellKit
import SwiftUI

class GearListController: GearBaseTableViewController, ModalTransitionListener, SwipeTableViewCellDelegate {
    
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var addButton: UIBarButtonItem!
    private var observersAdded = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.rowHeight = 65
        searchBar.delegate = self
        
        // Listen for notifications from SwiftUI AddGearView (only add once)
        if !observersAdded {
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(handleGearSaved),
                name: NSNotification.Name("GearSaved"),
                object: nil
            )
            
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(handleGearCancelled),
                name: NSNotification.Name("GearCancelled"),
                object: nil
            )
            observersAdded = true
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        searchBar.barTintColor = UIColor.white
        addButton.tintColor = .white
    }
    
    @objc private func handleGearSaved() {
        // Dismiss the presented modal
        if let presentedController = presentedViewController {
            presentedController.dismiss(animated: true) { [weak self] in
                // Refresh the table view after dismissal
                self?.refreshGearList()
            }
        }
    }
    
    @objc private func handleGearCancelled() {
        // Dismiss the presented modal
        if let presentedController = presentedViewController {
            presentedController.dismiss(animated: true)
        }
    }
    
    private func refreshGearList() {
        // Refresh the gear brain data by reloading
        DispatchQueue.main.async { [weak self] in
            self?.loadGear()
        }
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
        let settingsController = SwiftUIMigrationHelper.shared.createSettingsViewController()
        present(settingsController, animated: true)
    }
    
    @IBAction func addButtonPressed(_ sender: UIBarButtonItem) {
        let addGearController = SwiftUIMigrationHelper.shared.createAddGearViewController()
        let navController = UINavigationController(rootViewController: addGearController)
        present(navController, animated: true)
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedGear = gearBrain?.getGear(indexPath: indexPath)
        let editGearController = SwiftUIMigrationHelper.shared.createAddGearViewController(gear: selectedGear)
        let navController = UINavigationController(rootViewController: editGearController)
        present(navController, animated: true)
        
        // Clear selection after navigation
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    // MARK: - Legacy segue support (can be removed once storyboard segues are eliminated)
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showAddGear" {
            let destinationVC = segue.destination as! AddGearViewController
            // If there's a selected row, we're editing; otherwise we're adding new
            if let indexPath = tableView.indexPathForSelectedRow {
                destinationVC.existingGear = gearBrain?.getGear(indexPath: indexPath)
            }
            // Clear selection after setting up the destination
            if let selectedIndexPath = tableView.indexPathForSelectedRow {
                tableView.deselectRow(at: selectedIndexPath, animated: false)
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


