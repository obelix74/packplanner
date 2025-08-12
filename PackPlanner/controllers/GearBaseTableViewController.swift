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
        navBarAppearance.backgroundColor = UIColor.systemRed
        
        navBar.standardAppearance = navBarAppearance
        navBar.scrollEdgeAppearance = navBarAppearance
        
        navBar.tintColor = UIColor.white
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
    
    func getGearBrain(_ search: String) -> GearBrain{
        return GearBrain.getFilteredGears(search: search)
    }
    
    func loadGear(search: String = "") {
        self.gearBrain = getGearBrain(search)
        tableView.reloadData()
        
        if (self.gearBrain!.isEmpty()) {
            let dict = getNoGearMessage()
            
            if (shouldShowAlert()) {
                let refreshAlert = UIAlertController(title: dict["title"], message: dict["message"], preferredStyle: UIAlertController.Style.alert)

                refreshAlert.addAction(UIAlertAction(title: "Dismiss", style: .default, handler: { (action: UIAlertAction!) in
                }))
                
                present(refreshAlert, animated: true, completion: nil)
            }
        }
    }
    
    func getNoGearMessage() -> [String:String]{
        var dict : [String:String] = [:]
        dict["title"] = "No gear found"
        dict["message"] = "Please add new gear"
        return dict
    }
    
    func shouldShowAlert() -> Bool {
        return SettingsManager.SINGLETON.settings.firstTimeUser
    }
    
    override func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        view.tintColor = UIColor.systemPurple
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
