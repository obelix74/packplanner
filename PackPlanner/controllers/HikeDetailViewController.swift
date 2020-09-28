//
//  HikeDetailViewController.swift
//  PackPlanner
//
//  Created by Kumar on 9/23/20.
//

import UIKit
import SwipeCellKit

class HikeDetailViewController: UITableViewController, SwipeTableViewCellDelegate, RefreshProtocol {
    
    var hikeBrain : HikeBrain?
    
    var existingHike : Hike?{
        didSet {
            self.hikeBrain = HikeBrain(existingHike!)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let hike = existingHike {
            self.title = hike.name
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
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
    
    //MARK: - button actions
    
    @IBAction func editHikeButtonSelected(_ sender: UIBarButtonItem) {
        performSegue(withIdentifier: "editHike", sender: self)
    }
    
    @IBAction func addGearButtonSelected(_ sender: UIBarButtonItem) {
        performSegue(withIdentifier: "addGearToHike", sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == "editHike") {
            let destinationVC = segue.destination as! AddHikeViewController
            destinationVC.hike = self.existingHike
        }
        else if (segue.identifier == "addGearToHike") {
            let destinationVC = segue.destination as! AddGearToHikeTableViewController
            destinationVC.hike = self.existingHike
        }
        else if (segue.identifier == "editHikeGear" && tableView.indexPathForSelectedRow != nil) {
            let destinationVC = segue.destination as! EditHikeGearController
            if let indexPath = tableView.indexPathForSelectedRow {
                destinationVC.hikeGear = self.hikeBrain?.getHikeGear(indexPath: indexPath)
                destinationVC.delegate = self
                destinationVC.indexPath = indexPath
            }
        }
    }
    
    //MARK: - Table data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        return self.hikeBrain!.getNumberSections() + 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if (section == 0) {
            return 1
        }
        else {
            return self.hikeBrain!.getNumberOfRowsInSection(section: section)
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if (section == 0) {
            return "Hike detail"
        }
        else {
            return self.hikeBrain!.getCategory(section: section)
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let section = indexPath.section
        if (section == 0) {
            let cell = tableView.dequeueReusableCell(withIdentifier: "titlePrototypeCell", for: indexPath) as! HikeDetailTableViewCell
            cell.hikeBrain = self.hikeBrain
            cell.selectionStyle = .none
            cell.contentView.backgroundColor = .flatGrayDark()
            return cell
        }
        else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "gearPrototypeCell", for: indexPath) as! HikeGearTableViewCell
            cell.hikeGear = self.hikeBrain?.getHikeGear(indexPath: indexPath)
            cell.hikeBrain = self.hikeBrain!
            cell.delegate = self
            cell.accessoryType = .disclosureIndicator
            return cell
        }
    }
    
    override func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        view.tintColor = UIColor.flatPlumDark()
        let header = view as! UITableViewHeaderFooterView
        header.textLabel?.textColor = UIColor.white
    }
    
    //MARK: - Table delegate
    
    func refresh(at indexPath: IndexPath) {
        let generalSection: IndexPath = IndexPath(row: 0, section: 0)
        tableView.reloadRows(at: [indexPath, generalSection], with: .fade)
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        performSegue(withIdentifier: "editHikeGear", sender: self)
    }
    
    //MARK: Swipe cell actions
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath, for orientation: SwipeActionsOrientation) -> [SwipeAction]? {
         if (orientation == .right) {
             let deleteAction = SwipeAction(style: .destructive, title: "Delete") { action, indexPath in
                 self.updateModel(at: indexPath)
                 action.fulfill(with: .delete)
                 self.refresh(at: indexPath)
             }
             
             // customize the action appearance
             deleteAction.image = UIImage(named: "delete-icon")
             
             return [deleteAction]
         }
         else {
             let hikeGear = self.hikeBrain!.getHikeGear(indexPath: indexPath)
             let verified = hikeGear!.verified
             let title = verified ? "Unverify" : "Verify"
             let verifyImage = verified ? "checkmark.seal" : "checkmark.seal.fill"
             let verifiedAction = SwipeAction(style: .default, title: title) { action, indexPath in
                 self.hikeBrain!.updateVerifiedToggle(hikeGear: hikeGear!)
                 self.refresh(at: indexPath)
             }
             
             // customize the action appearance
             verifiedAction.image = UIImage(named: verifyImage)
             
             return [verifiedAction]
         }
     }

    
    func updateModel(at indexPath: IndexPath) {
        print("UpdateModel called")
        let refreshAlert = UIAlertController(title: "Refresh", message: "Are you sure you want to delete? ", preferredStyle: UIAlertController.Style.alert)
        
        refreshAlert.addAction(UIAlertAction(title: "Delete", style: .default, handler: { (action: UIAlertAction!) in
            self.hikeBrain?.deleteHikeGearAt(indexPath: indexPath)
        }))
        
        refreshAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action: UIAlertAction!) in
        }))
        
        present(refreshAlert, animated: true, completion: nil)
    }
}
