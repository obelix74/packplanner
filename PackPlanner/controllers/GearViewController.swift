//
//  ItemViewController.swift
//  PackPlanner
//
//  Created by Kumar on 9/18/20.
//

import UIKit
import RealmSwift
import ChameleonFramework

class GearViewController: UITableViewController {
    
    let realm = try! Realm()
    var gears : Results<Gear>?
    let settings : Settings = SettingsManager.SINGLETON.settings

    
    @IBOutlet weak var addButton: UIBarButtonItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.rowHeight = 80.0
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
//        searchBar.barTintColor = .flatWhite()
        addButton.tintColor = .white
    }


    // MARK: - Table view data source
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let numberOfGears = gears?.count
        if numberOfGears == 0 {
            return 1
        } else {
            return gears!.count
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "gearCell", for: indexPath) as! GearTableViewCell
        if (gears?.count == 0) {
            cell.nameLabel.text = "No gear found"
        } else {
            let weightUnit = self.settings.imperial ? "Oz" : "Grams"

            let gear = gears?[indexPath.row]
            cell.nameLabel.text = gear?.name
            cell.descriptionLabel.text = gear?.desc
            if let weight = gear?.weight() {
                cell.weightLabel.text = String(format:"%.2f", weight) + " " + weightUnit
            }
        }
        return cell
    }
    
    
    @IBAction func showSettings(_ sender: UIBarButtonItem) {
        performSegue(withIdentifier: "showSettings", sender: self)

    }
    
    @IBAction func addButtonPressed(_ sender: UIBarButtonItem) {
        performSegue(withIdentifier: "showAddGear", sender: self)
    }
    
    func loadGear() {
        gears = realm.objects(Gear.self)
        tableView.reloadData()
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
}
