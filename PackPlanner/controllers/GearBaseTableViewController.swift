//
//  GearBaseTableViewController.swift
//  PackPlanner
//
//  Created by Kumar on 9/23/20.
//

import UIKit
import RealmSwift

class GearBaseTableViewController: UITableViewController {

    let realm = try! Realm()
    var gears : Results<Gear>?
    var categoryMap : [String: [Gear]]? = [:]
    var categoriesSorted : [String]?
    let settings : Settings = SettingsManager.SINGLETON.settings
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
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
    }
    
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
    
    
    func loadGear(search: String = "") {
        gears = realm.objects(Gear.self)
        
        if (!search.isEmpty) {
            gears = gears?.filter("name CONTAINS[cd] %@", search).sorted(byKeyPath: "name", ascending: true)
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
    
    override func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        view.tintColor = UIColor.flatPlumDark()
        let header = view as! UITableViewHeaderFooterView
        header.textLabel?.textColor = UIColor.white
    }
}

//MARK: - Searchbar delegate methods

extension GearBaseTableViewController: UISearchBarDelegate {
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
