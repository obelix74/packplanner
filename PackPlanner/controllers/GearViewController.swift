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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.rowHeight = 80.0
        
        loadGear()
    }
    
    override func viewWillAppear(_ animated: Bool) {
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
//        addButton.tintColor = .white
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
        let cell = tableView.dequeueReusableCell(withIdentifier: "gearCell", for: indexPath)
        cell.textLabel?.text = "No gear found"
        return cell
    }
    
    
    @IBAction func showSettings(_ sender: UIBarButtonItem) {
        performSegue(withIdentifier: "showSettings", sender: self)

    }
    
    func loadGear() {
        gears = realm.objects(Gear.self)
        tableView.reloadData()
    }
}
