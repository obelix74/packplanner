//
//  GearTableViewCell.swift
//  PackPlanner
//
//  Created by Kumar on 9/22/20.
//

import UIKit
import SwipeCellKit
import CoreData

class GearTableViewCell: SwipeTableViewCell {

    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var weightLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!

    // Core Data version
    var existingGearCoreData: GearEntity? {
        didSet {
            guard let gear = existingGearCoreData else { return }
            self.nameLabel.text = gear.name
            if (self.descriptionLabel != nil) {
                self.descriptionLabel.text = gear.desc
            }
            self.weightLabel.text = gear.weightString(imperial: SettingsManagerCD.SINGLETON.settings.imperial)
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.nameLabel.lineBreakMode = .byWordWrapping
        self.nameLabel.numberOfLines = 0
        if (self.descriptionLabel != nil) {
            self.descriptionLabel.lineBreakMode = .byWordWrapping
            self.descriptionLabel.numberOfLines = 0
        }
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
