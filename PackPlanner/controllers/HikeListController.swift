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
import CSV

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
        let cell = tableView.dequeueReusableCell(withIdentifier: "hikeCell", for: indexPath) as! HikeListTableViewCell
        cell.delegate = self
        
        if (self.hikes?.count == 0) {
            cell.nameLabel.text = "No hikes found, please add"
            cell.descriptionLabel.text = ""
            cell.noItemsLabel.text = ""
        } else {
            let hike = self.hikes![indexPath.row]
            cell.existingHike = hike
            cell.accessoryType = .disclosureIndicator
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
            return [exportAction]
        }
    }
    
    func exportHikeAt(at indexPath: IndexPath) {
        let hike = self.hikes![indexPath.row]
        do {
            let fileURL = try TemporaryFile(creatingTempDirectoryForFilename: "\(hike.name.replacingOccurrences(of: " ", with: "_")).csv").fileURL
            let fileName = fileURL.path
            print("Writing CSV to file \(fileName)")
            let stream = OutputStream(toFileAtPath: fileName, append: false)!
            let csv = try! CSVWriter(stream: stream)
            
            // Write fields separately
            csv.beginNewRow()
            try! csv.write(field: "Name")
            try! csv.write(field: hike.name)
            
            csv.beginNewRow()
            try! csv.write(field: "Description")
            try! csv.write(field: hike.desc)
            
            csv.beginNewRow()
            try! csv.write(field: "Distance")
            try! csv.write(field: hike.distance)
            
            csv.beginNewRow()
            try! csv.write(field: "Location")
            try! csv.write(field: hike.location)
            
            csv.beginNewRow()
            try! csv.write(field: "Completed")
            try! csv.write(field: String(hike.completed))
            if (hike.externalLink1 != nil) {
                csv.beginNewRow()
                try! csv.write(field: "URL1")
                try! csv.write(field: hike.externalLink1!)
            }
            if (hike.externalLink2 != nil) {
                csv.beginNewRow()
                try! csv.write(field: "URL2")
                try! csv.write(field: hike.externalLink2!)
            }
            if (hike.externalLink3 != nil) {
                csv.beginNewRow()
                try! csv.write(field: "URL3")
                try! csv.write(field: hike.externalLink3!)
            }
            csv.beginNewRow()
            try! csv.write(field: "")
            csv.beginNewRow()
            try! csv.write(field:"Name")
            try! csv.write(field:"Description")
            try! csv.write(field:"Category")
            try! csv.write(field:"Weight (each)")
            try! csv.write(field:"Quantity")
            try! csv.write(field:"Consumable")
            try! csv.write(field:"Worn")
            try! csv.write(field:"Verified")

            let hikeGears = hike.hikeGears
            hikeGears.forEach { (hikeGear) in
                if let gear = hikeGear.gearList.first {
                    csv.beginNewRow()
                    try! csv.write(field: gear.name)
                    try! csv.write(field: gear.desc)
                    try! csv.write(field: gear.category)
                    try! csv.write(field: gear.weightString())
                    try! csv.write(field: String(hikeGear.numberUnits))
                    try! csv.write(field: String(hikeGear.consumable))
                    try! csv.write(field: String(hikeGear.worn))
                    try! csv.write(field: String(hikeGear.verified))
                }
            }
            
            let hikeBrain = HikeBrain(hike)
            csv.beginNewRow()
            try! csv.write(field: "")
            csv.beginNewRow()
            try! csv.write(field: "Total weight")
            try! csv.write(field: hikeBrain.getTotalWeight())
            csv.beginNewRow()
            try! csv.write(field: "Base weight")
            try! csv.write(field: hikeBrain.getBaseWeight())
            csv.beginNewRow()
            try! csv.write(field: "Consumable weight")
            try! csv.write(field: hikeBrain.getConsumableWeight())
            csv.beginNewRow()
            try! csv.write(field: "Worn weight")
            try! csv.write(field: hikeBrain.getWornWeight())

            
            csv.stream.close()
            
            // Create the Array which includes the files you want to share
            var filesToShare = [Any]()

            // Add the path of the file to the Array
            filesToShare.append(fileURL)

            // Make the activityViewContoller which shows the share-view
            let activityViewController = UIActivityViewController(activityItems: filesToShare, applicationActivities: nil)

            // Show the share-view
            self.present(activityViewController, animated: true, completion: nil)
        }
        catch {
            print("Error writing CSV \(error)")
        }
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
