//
//  HikeGearTableViewCell.swift
//  PackPlanner
//
//  Created by Kumar on 9/26/20.
//

import UIKit
import SwipeCellKit

class HikeGearTableViewCell: SwipeTableViewCell {
    
    var hikeGear: HikeGear? {
        didSet {
            updateLabels()
        }
    }
    
    var hikeBrain: HikeBrain? {
        didSet {
            
        }
    }
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var weightLabel: UILabel!
    @IBOutlet weak var wornSwitch: UISwitch!
    @IBOutlet weak var consumableSwitch: UISwitch!
    @IBOutlet weak var noLabel: UILabel!
    @IBOutlet weak var noStepper: UIStepper!
    @IBOutlet weak var verifiedSwitch: UISwitch!
    
    var refreshGeneralDelegate : RefreshGeneralProtocol?
    
    func updateLabels() {
        let gear = hikeGear!.gearList.first
        self.nameLabel.text = gear!.name
        self.descriptionLabel.text = gear!.desc
        self.weightLabel.text = gear!.weightString()
        self.wornSwitch.isOn = self.hikeGear!.worn
        self.consumableSwitch.isOn = self.hikeGear!.consumable
        self.noStepper.value = Double(self.hikeGear!.numberUnits)
        self.noLabel.text = String(format:"%.0f", self.noStepper.value)
    }
    
    func refreshParent() {
        if let delegate = refreshGeneralDelegate {
            delegate.refreshGeneralSection()
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
    
    @IBAction func wornSwitchToggled(_ sender: UISwitch) {
    }
    
    @IBAction func consumableSwitchToggled(_ sender: UISwitch) {
    }
    
    @IBAction func noStepperUsed(_ sender: UIStepper) {
    }
    
    @IBAction func verifiedSwitchToggled(_ sender: UISwitch) {
    }
    
}
