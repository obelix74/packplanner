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
    @IBOutlet weak var quantityLabel: UILabel!
    @IBOutlet weak var verifiedImage: UIImageView!
    @IBOutlet weak var consumableImage: UIImageView!
    @IBOutlet weak var wornImage: UIImageView!
        
    func updateLabels() {
        let gear = hikeGear!.gearList.first
        self.nameLabel.text = gear!.name
        self.descriptionLabel.text = gear!.desc
        self.weightLabel.text = gear!.weightString()
        self.quantityLabel.text = String("Quantity: \(hikeGear!.numberUnits)")
        self.consumableImage.image = hikeGear!.consumable ? UIImage(named: "consumable_highlighted") : UIImage(named: "consumable")
        let verifyImage = hikeGear!.verified ? "checkmark.seal.fill" : "checkmark.seal"
        self.verifiedImage.image = UIImage(systemName: verifyImage)
        self.wornImage.image = hikeGear!.worn ? UIImage(named: "worn_highlighted") : UIImage(named: "worn")
    }
     
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
}
