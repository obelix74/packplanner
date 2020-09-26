//
//  HikeDetailViewController.swift
//  PackPlanner
//
//  Created by Kumar on 9/23/20.
//

import UIKit

class HikeDetailViewController: UITableViewController {
    
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
          return UITableViewCell()
        }
    }
    
    override func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        view.tintColor = UIColor.flatPlumDark()
        let header = view as! UITableViewHeaderFooterView
        header.textLabel?.textColor = UIColor.white
    }
    
    //MARK: - Table delegate
}
