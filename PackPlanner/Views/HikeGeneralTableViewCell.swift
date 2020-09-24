//
//  HikeTableViewCell.swift
//  PackPlanner
//
//  Created by Kumar on 9/23/20.
//

import UIKit
import SwipeCellKit

class HikeGeneralTableViewCell: SwipeTableViewCell {

    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var noItemsLabel: UILabel!
    
    var existingHike : Hike?  {
        didSet {
            self.nameLabel.text = existingHike!.name
            self.descriptionLabel.text = existingHike!.desc
            self.noItemsLabel.text = String("\(existingHike!.hikeGears.count) gear")
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
