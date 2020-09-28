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
        self.consumableImage.isHighlighted = hikeGear!.consumable
        self.verifiedImage.isHighlighted = hikeGear!.verified
        self.wornImage.isHighlighted = hikeGear!.worn
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
