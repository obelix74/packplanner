//
//  ItemViewController.swift
//  PackPlanner
//
//  Created by Kumar on 9/18/20.
//

import UIKit
import RealmSwift
import ChameleonFramework

class GearViewController: UITableViewController, ModalTransitionListener {
    
    func popoverDismissed() {
        tableView.reloadData()
    }
    
    
    let realm = try! Realm()
    var gears : Results<Gear>?
    var categoryMap : [String: [Gear]]? = [:]
    var categoriesSorted : [String]?
    let settings : Settings = SettingsManager.SINGLETON.settings
    
    
    @IBOutlet weak var addButton: UIBarButtonItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.rowHeight = 100.0
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
        if (gears?.count == 0) {
            cell.nameLabel.text = "No gear found"
        } else {
            let weightUnit = self.settings.imperial ? "Oz" : "Grams"
            
            let section = indexPath.section
            let category = categoriesSorted?[section]
            if (category != nil) {
                let gearsInSection = categoryMap![category!]
                let gear = gearsInSection![indexPath.row]
                cell.nameLabel.text = gear.name
                cell.descriptionLabel.text = gear.desc
                cell.weightLabel.text = String(format:"%.2f", gear.weight()) + " " + weightUnit
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
    
    func loadGear() {
        gears = realm.objects(Gear.self)
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
