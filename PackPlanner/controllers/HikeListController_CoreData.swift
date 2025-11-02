//
//  HikeListController.swift
//  PackPlanner
//
//  Core Data version
//

import UIKit
import CoreData
import SwipeCellKit
import SwiftUI

class HikeListController: UITableViewController, SwipeTableViewCellDelegate, NavigationStyling {

    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var addButton: UIBarButtonItem!

    private var context: NSManagedObjectContext {
        return CoreDataStack.shared.viewContext
    }

    var fetchedResultsController: NSFetchedResultsController<HikeEntity>!
    private var observersAdded = false
    private var searchText: String = ""

    // Dependency injection using property wrappers
    @Injected private var hikeLogic: HikeListService
    @Injected private var alertLogic: AlertService
    @Injected private var exportLogic: ExportService

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.rowHeight = 100.0

        // Setup Core Data fetched results controller
        setupFetchedResultsController()

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

            // Listen for CloudKit changes
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(handleCloudKitChange),
                name: .cloudKitDataChanged,
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

    // MARK: - Core Data Setup

    func setupFetchedResultsController(search: String = "") {
        let fetchRequest: NSFetchRequest<HikeEntity> = HikeEntity.fetchRequest()

        // Add search predicate if needed
        if !search.isEmpty {
            fetchRequest.predicate = NSPredicate(format: "name CONTAINS[cd] %@", search)
        }

        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]

        fetchedResultsController = NSFetchedResultsController(
            fetchRequest: fetchRequest,
            managedObjectContext: context,
            sectionNameKeyPath: nil,
            cacheName: nil
        )

        fetchedResultsController.delegate = self

        do {
            try fetchedResultsController.performFetch()
        } catch {
            print("❌ Error fetching hikes: \(error)")
        }
    }

    func loadHikes(search: String = "") {
        searchText = search
        setupFetchedResultsController(search: search)
        tableView.reloadData()
    }

    @objc private func handleHikeSaved() {
        // Dismiss the presented modal
        if let presentedController = presentedViewController {
            presentedController.dismiss(animated: true) { [weak self] in
                // Refresh will happen automatically via NSFetchedResultsController
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

    @objc private func handleCloudKitChange() {
        print("📡 CloudKit data changed, refreshing hikes")
        DispatchQueue.main.async { [weak self] in
            self?.refreshHikeList()
        }
    }

    private func refreshHikeList() {
        // Refresh the hike data
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            do {
                try self.fetchedResultsController.performFetch()
                self.tableView.reloadData()
            } catch {
                print("❌ Error refreshing hikes: \(error)")
            }
        }
    }

    // MARK: - Table view data source

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let hikeCount = fetchedResultsController.fetchedObjects?.count ?? 0

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

        let hike = fetchedResultsController.object(at: indexPath)

        // Convert HikeEntity to Hike for cell (temporary during migration)
        // TODO: Update HikeListTableViewCell to accept HikeEntity directly
        cell.existingHikeCoreData = hike
        cell.accessoryType = .disclosureIndicator

        return cell
    }

    //MARK: - Tableview delegate methods
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedHike = fetchedResultsController.object(at: indexPath)
        let hikeDetailController = SwiftUIMigrationHelper.shared.createHikeDetailViewController(hikeCoreData: selectedHike)
        navigationController?.pushViewController(hikeDetailController, animated: true)

        // Clear selection after navigation
        tableView.deselectRow(at: indexPath, animated: true)
    }

    // MARK: - Legacy segue support (can be removed once storyboard segues are eliminated)
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == "showHikeDetail" && tableView.indexPathForSelectedRow != nil) {
            let destinationVC = segue.destination as! HikeDetailViewController
            if let indexPath = tableView.indexPathForSelectedRow {
                destinationVC.existingHikeCoreData = fetchedResultsController.object(at: indexPath)
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
                let hike = self.fetchedResultsController.object(at: indexPath)
                HikeBrainCD.copyHike(hike: hike)
                // Reload will happen automatically via NSFetchedResultsController
            }
            copyAction.hidesWhenSelected = true
            copyAction.image = UIImage(systemName: "doc")

            return [copyAction, exportAction]
        }
    }

    func exportHikeAt(at indexPath: IndexPath) {
        let hike = fetchedResultsController.object(at: indexPath)

        // Convert to Realm hike for export (temporary during migration)
        // TODO: Update exportLogic to accept HikeEntity
        // For now, create a temporary conversion or update ExportService

        // Use shared export logic - need to update ExportService for Core Data
        // exportLogic.exportHike(hike, presenter: self)

        print("⚠️ Export needs to be updated for Core Data")
        let alert = UIAlertController(title: "Export", message: "Export feature will be available after full migration.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)

        self.tableView.reloadData()
    }

    func updateModel(at indexPath: IndexPath) {
        let hike = fetchedResultsController.object(at: indexPath)

        // Use shared alert logic
        let deleteAlert = alertLogic.createDeleteConfirmationAlert(
            itemName: "Hike",
            onConfirm: {
                self.context.delete(hike)

                do {
                    try self.context.save()
                    print("✅ Hike deleted successfully")
                    // Reload happens automatically via NSFetchedResultsController
                } catch {
                    print("❌ Error deleting hike: \(error)")
                    self.context.rollback()
                    self.tableView.reloadData()
                }
            },
            onCancel: {
                self.tableView.reloadData()
            }
        )

        present(deleteAlert, animated: true)
    }
}

// MARK: - NSFetchedResultsControllerDelegate

extension HikeListController: NSFetchedResultsControllerDelegate {

    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.beginUpdates()
    }

    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>,
                    didChange anObject: Any,
                    at indexPath: IndexPath?,
                    for type: NSFetchedResultsChangeType,
                    newIndexPath: IndexPath?) {

        switch type {
        case .insert:
            if let indexPath = newIndexPath {
                tableView.insertRows(at: [indexPath], with: .automatic)
            }
        case .delete:
            if let indexPath = indexPath {
                tableView.deleteRows(at: [indexPath], with: .automatic)
            }
        case .update:
            if let indexPath = indexPath {
                tableView.reloadRows(at: [indexPath], with: .automatic)
            }
        case .move:
            if let indexPath = indexPath, let newIndexPath = newIndexPath {
                tableView.deleteRows(at: [indexPath], with: .automatic)
                tableView.insertRows(at: [newIndexPath], with: .automatic)
            }
        @unknown default:
            tableView.reloadData()
        }
    }

    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.endUpdates()
    }
}
