//
//  GearTableViewCell.swift
//  PackPlanner
//
//  Created by Kumar on 9/22/20.
//

import UIKit
import SwipeCellKit

class GearTableViewCell: SwipeTableViewCell {

    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var weightLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    let settings : Settings = SettingsManager.SINGLETON.settings

    var existingGear : Gear?  {
        didSet {
            let weightUnit = self.settings.imperial ? "Oz" : "Grams"
            self.nameLabel.text = existingGear!.name
            self.descriptionLabel.text = existingGear!.desc
            self.weightLabel.text = String(format:"%.2f", existingGear!.weight()) + " " + weightUnit
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

}
