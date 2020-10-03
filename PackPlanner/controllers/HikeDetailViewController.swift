//
//  HikeDetailViewController.swift
//  PackPlanner
//
//  Created by Kumar on 9/23/20.
//

import UIKit
import SwipeCellKit

class HikeDetailViewController: UIViewController, SwipeTableViewCellDelegate, RefreshProtocol, UITableViewDelegate, UITableViewDataSource {
    
    var hikeBrain : HikeBrain?
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var noGearLabel: UILabel!
    @IBOutlet weak var totalWeightLabel: UILabel!
    @IBOutlet weak var pendingSwitchToggled: UISegmentedControl!

    
    var existingHike : Hike?{
        didSet {
            self.hikeBrain = HikeBrain(existingHike!)
        }
    }
    
    fileprivate func updateSummaryLabels() {
        self.nameLabel.text = existingHike?.name
        self.descriptionLabel.text = existingHike?.desc
        self.noGearLabel.text = String("Gear: \(self.existingHike!.hikeGears.count)")
        self.totalWeightLabel.text = self.hikeBrain?.getTotalWeight()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let hike = existingHike {
            self.title = hike.name
        }
        
        self.tableView.delegate = self
        self.tableView.dataSource = self
        updateSummaryLabels()
    }
    
    @IBAction func pendingSwitchToggled(_ sender: UISegmentedControl) {
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
    
    @IBAction func reportsButtonSelected(_ sender: UIBarButtonItem) {
        performSegue(withIdentifier: "showReport", sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == "editHike") {
            let destinationVC = segue.destination as! AddHikeViewController
            destinationVC.hike = self.existingHike
            destinationVC.delegate = self 
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
                destinationVC.hikeBrain = self.hikeBrain
            }
        }
        else if (segue.identifier == "showReport") {
            let destinationVC = segue.destination as! HikeReportController
            destinationVC.hikeBrain = self.hikeBrain
        }
    }
    
    //MARK: - Table data source
    func numberOfSections(in tableView: UITableView) -> Int {
        return self.hikeBrain!.getNumberSections()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.hikeBrain!.getNumberOfRowsInSection(section: section)
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return self.hikeBrain!.getCategory(section: section)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "gearPrototypeCell", for: indexPath) as! HikeGearTableViewCell
        cell.hikeGear = self.hikeBrain?.getHikeGear(indexPath: indexPath)
        cell.hikeBrain = self.hikeBrain!
        cell.delegate = self
        cell.accessoryType = .disclosureIndicator
        return cell
    }
    
    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        view.tintColor = UIColor.flatPlumDark()
        let header = view as! UITableViewHeaderFooterView
        header.textLabel?.textColor = UIColor.white
    }
    
    //MARK: - Table delegate
    
    func refresh(at indexPath: IndexPath) {
        updateSummaryLabels()
        tableView.reloadRows(at: [indexPath], with: .fade)
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        performSegue(withIdentifier: "editHikeGear", sender: self)
    }
    
    //MARK: Swipe cell actions
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath, for orientation: SwipeActionsOrientation) -> [SwipeAction]? {
        if (orientation == .right) {
            let deleteAction = SwipeAction(style: .destructive, title: "Delete") { action, indexPath in
                self.deleteGear(at: indexPath)
                action.fulfill(with: .delete)
                self.refresh(at: indexPath)
            }
            
            // customize the action appearance
            deleteAction.image = UIImage(systemName: "trash")
            
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
            verifiedAction.image = UIImage(systemName: verifyImage)
            
            return [verifiedAction]
        }
    }
    
    
    func deleteGear(at indexPath: IndexPath) {
        print("UpdateModel called")
        let refreshAlert = UIAlertController(title: "Refresh", message: "Are you sure you want to delete? ", preferredStyle: UIAlertController.Style.alert)
        
        refreshAlert.addAction(UIAlertAction(title: "Delete", style: .default, handler: { (action: UIAlertAction!) in
            self.hikeBrain?.deleteHikeGearAt(indexPath: indexPath)
            self.tableView.reloadData()
        }))
        
        refreshAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action: UIAlertAction!) in
        }))
        
        present(refreshAlert, animated: true, completion: nil)
    }
}
