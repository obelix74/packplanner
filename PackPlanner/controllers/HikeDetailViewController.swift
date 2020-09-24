//
//  HikeDetailViewController.swift
//  PackPlanner
//
//  Created by Kumar on 9/23/20.
//

import UIKit

class HikeDetailViewController: BaseViewController {
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    
    var existingHike : Hike?{
        didSet {
            
        }
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let hike = existingHike {
            self.nameLabel.text = hike.name
            self.descriptionLabel.text = hike.desc
            self.title = hike.name
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let hike = existingHike {
            self.nameLabel.text = hike.name
            self.descriptionLabel.text = hike.desc
            self.title = hike.name
        }
    }
    
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
}
