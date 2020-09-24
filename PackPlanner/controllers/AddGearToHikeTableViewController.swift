//
//  AddGearToHikeTableViewController.swift
//  PackPlanner
//
//  Created by Kumar on 9/23/20.
//

import UIKit
import ChameleonFramework
import RealmSwift

class AddGearToHikeTableViewController: GearBaseTableViewController {

    @IBOutlet weak var searchBar: UISearchBar!
    
    var hike : Hike? {
        didSet {
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        searchBar.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if (hike != nil) {
            self.title = "Adding gear to \(hike!.name)"
        }
    }
    

    // MARK: - Table view data source
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "gearCell", for: indexPath) as! AddGearToHikeTableViewCell
        
        if (gearBrain?.gears?.count == 0) {
            cell.textLabel?.text = "No gears found"
        } else {
            cell.gear = gearBrain?.getGear(indexPath: indexPath)
        }
        return cell
    }
}
