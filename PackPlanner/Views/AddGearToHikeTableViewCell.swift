//
//  AddGearToHikeTableViewCell.swift
//  PackPlanner
//
//  Created by Kumar on 9/23/20.
//

import UIKit

class AddGearToHikeTableViewCell: UITableViewCell {

    var gear: Gear? {
        didSet {
            self.nameLabel.text = gear!.name
            self.weightLabel.text = String(format:"%.2f", gear!.weight())
        }
    }
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var weightLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
