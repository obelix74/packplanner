//
//  TripViewController.swift
//  PackPlanner
//
//  Created by Kumar on 9/18/20.
//

import UIKit
import RealmSwift
import ChameleonFramework
import SwipeCellKit

class HikeListController: UITableViewController, SwipeTableViewCellDelegate {
    
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var addButton: UIBarButtonItem!
    
    let realm = try! Realm()
    var hikes : Results<Hike>?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.rowHeight = 100.0
    }
    
    override func viewWillAppear(_ animated: Bool) {
        loadHikes()
        
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
    
    func loadHikes(search: String = "") {
        self.hikes = realm.objects(Hike.self)
        
        if (!search.isEmpty) {
            self.hikes = self.hikes?.filter("name CONTAINS[cd] %@", searchBar.text!).sorted(byKeyPath: "name", ascending: true)
        }
        tableView.reloadData()
    }
    
    // MARK: - Table view data source
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if (self.hikes!.isEmpty) {
            return 1
        } else {
            return self.hikes!.count
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "hikeCell", for: indexPath) as! HikeGeneralTableViewCell
        cell.delegate = self
        
        if (self.hikes?.count == 0) {
            cell.nameLabel.text = "No hikes found, please add"
            cell.descriptionLabel.text = ""
            cell.noItemsLabel.text = ""
        } else {
            let hike = self.hikes![indexPath.row]
            cell.existingHike = hike
            cell.accessoryType = .disclosureIndicator;
        }
        return cell
    }
    
    //MARK: - Tableview delegate methods
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        performSegue(withIdentifier: "showHikeDetail", sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == "showHikeDetail" && tableView.indexPathForSelectedRow != nil) {
            let destinationVC = segue.destination as! HikeDetailViewController
            if let indexPath = tableView.indexPathForSelectedRow {
                destinationVC.existingHike = hikes?[indexPath.row]
            }
        }
    }
    
    // MARK: Button actions
    @IBAction func settingsButtonPressed(_ sender: UIBarButtonItem) {
        performSegue(withIdentifier: "showSettings", sender: self)
    }
    
    @IBAction func addButtonSelected(_ sender: UIBarButtonItem) {
        performSegue(withIdentifier: "showAddHike", sender: self)
    }
    
    
    // MARK: Swipe table
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
        let refreshAlert = UIAlertController(title: "Refresh", message: "Are you sure you want to delete? ", preferredStyle: UIAlertController.Style.alert)
        
        refreshAlert.addAction(UIAlertAction(title: "Delete", style: .default, handler: { (action: UIAlertAction!) in
            do {
                try self.realm.write {
                    self.realm.delete(self.hikes![indexPath.row])
                    self.loadHikes()
                }
            }catch {
                print("Error deleting hike \(error)")
            }
        }))
        
        refreshAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action: UIAlertAction!) in
            self.tableView.reloadData()
        }))
        
        present(refreshAlert, animated: true, completion: nil)
    }
}
