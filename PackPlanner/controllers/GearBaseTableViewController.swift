//
//  GearBaseTableViewController.swift
//  PackPlanner
//
//  Created by Kumar on 9/23/20.
//

import UIKit
import RealmSwift

class GearBaseTableViewController: UITableViewController {
    let settings : Settings = SettingsManager.SINGLETON.settings
    var gearBrain : GearBrain?
    
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
        return self.gearBrain?.categoriesSorted?.count ?? 0
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return self.gearBrain?.getCategory(section: section)
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.gearBrain?.getGearsForSection(section: section)?.count ?? 0
    }
    
    
    func loadGear(search: String = "") {
        
        self.gearBrain = GearBrain.getFilteredGears(search: search)
        tableView.reloadData()
        
        if (self.gearBrain!.categoryMap!.isEmpty) {
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
