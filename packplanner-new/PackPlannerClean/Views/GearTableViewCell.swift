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

    var existingGear : Gear?  {
        didSet {
            self.nameLabel.text = existingGear!.name
            if (self.descriptionLabel != nil) {
                self.descriptionLabel.text = existingGear!.desc
            }
            self.weightLabel.text = existingGear?.weightString()
            print("\(existingGear!.name): \(existingGear!.uuid)")
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.nameLabel.lineBreakMode = .byWordWrapping
        if (self.descriptionLabel != nil) {
            self.descriptionLabel.lineBreakMode = .byWordWrapping
        }
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
