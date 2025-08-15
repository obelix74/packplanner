//
//  GearBaseTableViewController.swift
//  PackPlanner
//
//  Created by Kumar on 9/23/20.
//

import UIKit
import RealmSwift

class GearBaseTableViewController: UITableViewController, NavigationStyling {
    lazy var settings : Settings = SettingsManager.SINGLETON.settings
    var gearBrain : GearBrain?
    private let gearLogic = GearListLogic.shared
    private let alertLogic = AlertLogic.shared
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        loadGear()

        guard let navBar = navigationController?.navigationBar else {
            print("Warning: No navigation controller available for styling")
            return
        }
        
        // Use shared navigation styling logic
        applyStandardNavigationStyling(to: navBar)
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
        // Clean up duplicates on first load (when no search)
        if search.isEmpty {
            GearBrain.cleanupDuplicateGears()
        }
        
        self.gearBrain = getGearBrain(search)
        tableView.reloadData()
        
        if (self.gearBrain!.isEmpty()) {
            // Use shared gear logic for welcome message
            if gearLogic.shouldShowWelcomeMessage(gearCount: 0) {
                let (title, message) = gearLogic.getWelcomeMessage()
                let welcomeAlert = alertLogic.createWelcomeAlert(title: title, message: message)
                present(welcomeAlert, animated: true)
            }
        }
    }
    
    // Legacy methods - now using shared logic but keeping for backward compatibility
    func getNoGearMessage() -> [String:String]{
        let (title, message) = gearLogic.getWelcomeMessage()
        return ["title": title, "message": message]
    }
    
    func shouldShowAlert() -> Bool {
        return gearLogic.shouldShowWelcomeMessage(gearCount: 0)
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
