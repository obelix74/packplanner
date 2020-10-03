//
//  EditHikeGearController.swift
//  PackPlanner
//
//  Created by Kumar on 9/27/20.
//

import UIKit
import ChameleonFramework

class EditHikeGearController: UIViewController {

    @IBOutlet weak var doneButton: UIBarButtonItem!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var weightLabel: UILabel!
    @IBOutlet weak var quantityLabel: UILabel!
    @IBOutlet weak var quantityStepper: UIStepper!
    @IBOutlet weak var consumableImage: UIImageView!
    @IBOutlet weak var consumableSwitch: UISwitch!
    @IBOutlet weak var wornImage: UIImageView!
    @IBOutlet weak var wornSwitch: UISwitch!
    
    var gear : Gear?
    var hikeGear : HikeGear? {
        didSet {
            self.gear = hikeGear!.gearList.first
        }
    }
    var hikeBrain : HikeBrain?
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.doneButton.tintColor = .flatWhite()
        
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
        
        self.title = self.gear?.name
        updateLabels()
    }
    
    var delegate: RefreshProtocol?
    var indexPath: IndexPath?
    
    func updateLabels() {
        self.nameLabel.text = self.gear?.name
        self.descriptionLabel.text = self.gear?.desc
        self.weightLabel.text = self.gear?.weightString()
        self.quantityStepper.value = Double(self.hikeGear!.numberUnits)
        self.quantityLabel.text = String(format: "%.0f", self.quantityStepper.value)
        self.consumableImage.isHighlighted = self.hikeGear!.consumable
        self.consumableSwitch.isOn = self.hikeGear!.consumable
        self.wornImage.isHighlighted = self.hikeGear!.worn
        self.wornSwitch.isOn = self.hikeGear!.worn
    }
    
    
    @IBAction func doneButtonPressed(_ sender: UIBarButtonItem) {
        _ = navigationController?.popViewController(animated: true)

        if (self.delegate != nil) {
            delegate?.refresh(at: self.indexPath!)
        }
    }
    
    @IBAction func quantityStepperSelected(_ sender: UIStepper) {
        let number = Int(sender.value)
        self.hikeBrain!.setNumber(hikeGear: self.hikeGear!, number: number)
        self.quantityLabel.text = String(number)
    }
    
    @IBAction func consumableSwitchSelected(_ sender: UISwitch) {
        self.hikeBrain!.updateConsumableToggle(hikeGear: self.hikeGear!)
        self.consumableImage.isHighlighted = hikeGear!.consumable
    }
    
    @IBAction func wornSwitchSelected(_ sender: UISwitch) {
        self.hikeBrain!.updateWornToggle(hikeGear: self.hikeGear!)
        self.wornImage.isHighlighted = hikeGear!.worn
    }
    
}
