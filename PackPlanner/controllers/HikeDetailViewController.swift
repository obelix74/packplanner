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
            self.hikeBrain = HikeBrain(existingHike!, false)
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
        let selected = sender.selectedSegmentIndex
        if (selected == 0) {
            self.hikeBrain = HikeBrain(existingHike!, false);
        }
        else {
            self.hikeBrain = HikeBrain(existingHike!, true);
        }
        self.tableView.reloadData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Reload data when view appears to ensure it's up to date
        self.tableView.reloadData()
        updateSummaryLabels()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
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
        view.tintColor = UIColor.systemPurple
        let header = view as! UITableViewHeaderFooterView
        header.textLabel?.textColor = UIColor.white
    }
    
    //MARK: - Table delegate
    
    func refresh(at indexPath: IndexPath?) {
        updateSummaryLabels()
        if (indexPath != nil) {
            tableView.reloadRows(at: [indexPath!], with: .fade)
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        performSegue(withIdentifier: "editHikeGear", sender: self)
    }
    
    //MARK: Swipe cell actions
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath, for orientation: SwipeActionsOrientation) -> [SwipeAction]? {
        if (orientation == .right) {
            let deleteAction = SwipeAction(style: .destructive, title: "Remove") { action, indexPath in
                self.removeGear(at: indexPath)
                self.refresh(at: indexPath)
                action.fulfill(with: .delete)
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
                self.tableView.reloadData()
            }
            // customize the action appearance
            verifiedAction.image = UIImage(systemName: verifyImage)
            
            let worn = hikeGear!.worn
            let wornTitle = worn ? "Not worn" : "Worn"
            let wornImage = worn ? "worn" : "worn_highlighted"
            let wornAction = SwipeAction(style: .default, title: wornTitle) {action, indexPath in
                self.hikeBrain!.updateWornToggle(hikeGear: hikeGear!)
                self.refresh(at: indexPath)
            }
            wornAction.image = UIGraphicsImageRenderer(size: CGSize(width: 30, height: 30)).image { _ in
                UIImage(named: wornImage)?.draw(in: CGRect(x: 0, y: 0, width: 30, height: 30))
            }
            
            let consumable = hikeGear!.consumable
            let consumableTitle = consumable ? "Not cons" : "Consumable"
            let consumableImage = consumable ? "consumable" : "consumable_highlighted"
            let consumableAction = SwipeAction(style: .default, title: consumableTitle) {action, indexPath in
                self.hikeBrain!.updateConsumableToggle(hikeGear: hikeGear!)
                self.refresh(at: indexPath)
            }
            consumableAction.image = UIGraphicsImageRenderer(size: CGSize(width: 30, height: 30)).image { _ in
                UIImage(named: consumableImage)?.draw(in: CGRect(x: 0, y: 0, width: 30, height: 30))
            }

            return [verifiedAction, consumableAction, wornAction]
        }
    }
    
    
    func removeGear(at indexPath: IndexPath) {
        let refreshAlert = UIAlertController(title: "Refresh", message: "Are you sure you want to remove? ", preferredStyle: UIAlertController.Style.alert)
        
        refreshAlert.addAction(UIAlertAction(title: "Delete", style: .default, handler: { (action: UIAlertAction!) in
            self.hikeBrain?.deleteHikeGearAt(indexPath: indexPath)
            self.updateSummaryLabels()
            self.tableView.reloadData()
        }))
        
        refreshAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action: UIAlertAction!) in
        }))
        
        present(refreshAlert, animated: true, completion: nil)
    }
}
