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

class GearViewController: UITableViewController, ModalTransitionListener, SwipeTableViewCellDelegate {
    
    func popoverDismissed() {
        tableView.reloadData()
    }
    
    
    let realm = try! Realm()
    var gears : Results<Gear>?
    var categoryMap : [String: [Gear]]? = [:]
    var categoriesSorted : [String]?
    let settings : Settings = SettingsManager.SINGLETON.settings
    @IBOutlet weak var searchBar: UISearchBar!
    
    @IBOutlet weak var addButton: UIBarButtonItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.rowHeight = 100.0
        searchBar.delegate = self 
    }
    
    override func viewWillAppear(_ animated: Bool) {
        loadGear()
        
        guard let navBar = navigationController?.navigationBar else { fatalError("Navigation controller does not exist.")
        }
        let navBarAppearance = UINavigationBarAppearance()
        navBarAppearance.configureWithOpaqueBackground()
        navBarAppearance.titleTextAttributes = [.foregroundColor: UIColor.white]
        navBarAppearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
        navBarAppearance.backgroundColor = .flatRedDark()
        
        navBar.standardAppearance = navBarAppearance
        navBar.scrollEdgeAppearance = navBarAppearance
        
        navBar.tintColor = .flatWhite()
        searchBar.barTintColor = .flatWhite()
        addButton.tintColor = .white
    }
    
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return categoriesSorted?.count ?? 0
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return categoriesSorted?[section]
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let category = categoriesSorted?[section]
        return categoryMap?[category!]?.count ?? 0
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "gearCell", for: indexPath) as! GearTableViewCell
        cell.delegate = self
        
        if (gears?.count == 0) {
            cell.nameLabel.text = "No gear found"
        } else {
            let section = indexPath.section
            let category = categoriesSorted?[section]
            if (category != nil) {
                let gearsInSection = categoryMap![category!]
                let gear = gearsInSection![indexPath.row]
                cell.existingGear = gear
                cell.accessoryType = .disclosureIndicator;
            }
            
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        view.tintColor = UIColor.flatPlumDark()
        let header = view as! UITableViewHeaderFooterView
        header.textLabel?.textColor = UIColor.white
    }
    
    @IBAction func showSettings(_ sender: UIBarButtonItem) {
        ModalTransitionMediator.instance.setListener(listener: self)
        performSegue(withIdentifier: "showSettings", sender: self)
        
    }
    
    @IBAction func addButtonPressed(_ sender: UIBarButtonItem) {
        performSegue(withIdentifier: "showAddGear", sender: self)
    }
    
    func loadGear(search: String = "") {
        gears = realm.objects(Gear.self)

        if (!search.isEmpty) {
            gears = gears?.filter("name CONTAINS[cd] %@", searchBar.text!).sorted(byKeyPath: "name", ascending: true)
        }
        
        categoryMap = [:]
        gears?.forEach({ (gear) in
            var gearArray = categoryMap?[gear.category]
            if (gearArray == nil) {
                gearArray = []
            }
            gearArray?.append(gear)
            categoryMap?[gear.category] = gearArray
        })
        
        categoriesSorted = categoryMap?.keys.sorted()
        tableView.reloadData()
        
        if (categoryMap!.isEmpty) {
            let refreshAlert = UIAlertController(title: "No gear found", message: "Please add some :)", preferredStyle: UIAlertController.Style.alert)
            
            refreshAlert.addAction(UIAlertAction(title: "Dismiss", style: .default, handler: { (action: UIAlertAction!) in
            }))
            
            present(refreshAlert, animated: true, completion: nil)
        }
    }
    
    //MARK: - Tableview delegate methods
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        performSegue(withIdentifier: "showAddGear", sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == "showAddGear" && tableView.indexPathForSelectedRow != nil) {
            let destinationVC = segue.destination as! AddGearViewController
            if let indexPath = tableView.indexPathForSelectedRow {
                destinationVC.existingGear = gears?[indexPath.row]
            }
        }
    }
    
    //MARK: Swipe
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath, for orientation: SwipeActionsOrientation) -> [SwipeAction]? {
        guard orientation == .right else { return nil }
        
        let deleteAction = SwipeAction(style: .destructive, title: "Delete") { action, indexPath in
            self.updateModel(at: indexPath)
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
            if let category = self.categoriesSorted?[section] {
                if let gears = self.categoryMap?[category] {
                    do {
                        try self.realm.write {
                            self.realm.delete(gears[indexPath.row])
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
}

//MARK: - Searchbar delegate methods

extension GearViewController: UISearchBarDelegate {
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        print("searchBar delegate called")
        loadGear(search: searchBar.text!)
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchBar.text?.count == 0 {
            loadGear()
            DispatchQueue.main.async {
                searchBar.resignFirstResponder()
            }
        }
    }
}
