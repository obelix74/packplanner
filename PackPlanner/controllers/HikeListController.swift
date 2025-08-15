//
//  TripViewController.swift
//  PackPlanner
//
//  Created by Kumar on 9/18/20.
//

import UIKit
import RealmSwift
import SwipeCellKit
import SwiftUI

class HikeListController: UITableViewController, SwipeTableViewCellDelegate, NavigationStyling {
    
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var addButton: UIBarButtonItem!
    
    private var realm: Realm!
    var hikes : Results<Hike>?
    private var observersAdded = false
    
    // Dependency injection using property wrappers
    @Injected private var hikeLogic: HikeListService
    @Injected private var alertLogic: AlertService
    @Injected private var exportLogic: ExportService
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Initialize Realm safely
        do {
            realm = try Realm()
        } catch {
            print("Critical: Failed to initialize Realm in HikeListController: \(error)")
            // Show user-friendly error and disable functionality
            let alert = UIAlertController(
                title: "Database Error", 
                message: "Unable to load your hikes. Please restart the app.", 
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
            // Disable functionality that requires database
            addButton.isEnabled = false
            return
        }
        
        tableView.rowHeight = 100.0
        
        // Listen for notifications from SwiftUI AddHikeView (only add once)
        if !observersAdded {
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(handleHikeSaved),
                name: NSNotification.Name("HikeSaved"),
                object: nil
            )
            
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(handleHikeCancelled),
                name: NSNotification.Name("HikeCancelled"),
                object: nil
            )
            observersAdded = true
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        loadHikes()
        
        guard let navBar = navigationController?.navigationBar else {
            print("Warning: No navigation controller available for styling")
            return
        }
        
        // Use shared navigation styling logic
        applyStandardNavigationStyling(to: navBar)
        searchBar.barTintColor = UIColor.white
        addButton.tintColor = .white
    }
    
    func loadHikes(search: String = "") {
        self.hikes = realm.objects(Hike.self)
        
        if (!search.isEmpty) {
            self.hikes = self.hikes?.filter("name CONTAINS[cd] %@", searchBar.text!).sorted(byKeyPath: "name", ascending: true)
        }
        tableView.reloadData()
    }
    
    @objc private func handleHikeSaved() {
        // Dismiss the presented modal
        if let presentedController = presentedViewController {
            presentedController.dismiss(animated: true) { [weak self] in
                // Refresh the table view after dismissal
                self?.refreshHikeList()
            }
        }
    }
    
    @objc private func handleHikeCancelled() {
        // Dismiss the presented modal
        if let presentedController = presentedViewController {
            presentedController.dismiss(animated: true)
        }
    }
    
    private func refreshHikeList() {
        // Refresh the hike data
        DispatchQueue.main.async { [weak self] in
            self?.loadHikes()
        }
    }
    
    // MARK: - Table view data source
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let hikeCount = self.hikes!.count
        
        // Use shared welcome message logic
        if hikeLogic.shouldShowWelcomeMessage(hikeCount: hikeCount) {
            let (title, message) = hikeLogic.getWelcomeMessage()
            let welcomeAlert = alertLogic.createWelcomeAlert(title: title, message: message)
            present(welcomeAlert, animated: true)
            hikeLogic.markFirstTimeUserComplete()
        }
        
        return hikeCount
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "hikeCell", for: indexPath) as! HikeListTableViewCell
        cell.delegate = self
        
        
        let hike = self.hikes![indexPath.row]
        cell.existingHike = hike
        cell.accessoryType = .disclosureIndicator
        
        return cell
    }
    
    //MARK: - Tableview delegate methods
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedHike = hikes![indexPath.row]
        let hikeDetailController = SwiftUIMigrationHelper.shared.createHikeDetailViewController(hike: selectedHike)
        navigationController?.pushViewController(hikeDetailController, animated: true)
        
        // Clear selection after navigation
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    // MARK: - Legacy segue support (can be removed once storyboard segues are eliminated)
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == "showHikeDetail" && tableView.indexPathForSelectedRow != nil) {
            let destinationVC = segue.destination as! HikeDetailViewController
            if let indexPath = tableView.indexPathForSelectedRow {
                destinationVC.existingHike = hikes?[indexPath.row]
            }
        } else if segue.identifier == "showAddHike" {
            // AddHikeViewController doesn't need any special configuration for new hikes
            // existingHike will be nil by default
        }
    }
    
    // MARK: Button actions
    @IBAction func settingsButtonPressed(_ sender: UIBarButtonItem) {
        let settingsController = SwiftUIMigrationHelper.shared.createSettingsViewController()
        present(settingsController, animated: true)
    }
    
    @IBAction func addButtonSelected(_ sender: UIBarButtonItem) {
        let addHikeController = SwiftUIMigrationHelper.shared.createAddHikeViewController()
        let navController = UINavigationController(rootViewController: addHikeController)
        present(navController, animated: true)
    }
    
    
    // MARK: Swipe table
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
            let exportAction = SwipeAction(style: .default, title: "Export") { action, indexPath in
                self.exportHikeAt(at: indexPath)
            }
            exportAction.hidesWhenSelected = true
            exportAction.image = UIImage(systemName: "square.and.arrow.up")
            
            let copyAction = SwipeAction(style: .default, title: "Copy") { action, indexPath in
                let hike = self.hikes![indexPath.row]
                let hikeSwiftUI = HikeSwiftUI(from: hike)
                self.hikeLogic.copyHike(hikeSwiftUI)
                self.loadHikes()
            }
            copyAction.hidesWhenSelected = true
            copyAction.image = UIImage(systemName: "doc")
            
            return [copyAction, exportAction]
        }
    }
    
    func exportHikeAt(at indexPath: IndexPath) {
        let hike = self.hikes![indexPath.row]
        // Use shared export logic
        exportLogic.exportHike(hike, presenter: self)
        self.tableView.reloadData()
    }
    
    func updateModel(at indexPath: IndexPath) {
        let hike = self.hikes![indexPath.row]
        
        // Use shared alert logic
        let deleteAlert = alertLogic.createDeleteConfirmationAlert(
            itemName: "Hike",
            onConfirm: {
                let hikeSwiftUI = HikeSwiftUI(from: hike)
                self.hikeLogic.deleteHike(hikeSwiftUI) { success in
                    if success {
                        self.loadHikes()
                    }
                }
            },
            onCancel: {
                self.tableView.reloadData()
            }
        )
        
        present(deleteAlert, animated: true)
    }
}
