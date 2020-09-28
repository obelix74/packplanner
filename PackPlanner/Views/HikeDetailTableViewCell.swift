//
//  HikeDetailTableViewCell.swift
//  PackPlanner
//
//  Created by Kumar on 9/25/20.
//

import UIKit
import ChameleonFramework

class HikeDetailTableViewCell: UITableViewCell {

    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var noGearLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var totalWeightLabel: UILabel!
    
    var hikeBrain : HikeBrain? {
        didSet {
            updateLabels()
        }
    }
    
    func updateLabels() {
        let hike = hikeBrain!.hike
        
        self.nameLabel.textColor = .flatWhite()
        self.noGearLabel.textColor = .flatWhite()
        self.descriptionLabel.textColor = .flatWhite()
        self.totalWeightLabel.textColor = .flatWhite()
        
        self.nameLabel.text = hike.name
        self.noGearLabel.text = "# Gears:\(hike.hikeGears.count)"
        self.descriptionLabel.text = hike.desc
        self.totalWeightLabel.text = "Total Weight: \(hikeBrain!.getTotalWeight())"
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
