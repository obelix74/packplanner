//
//  HikeTableViewCell.swift
//  PackPlanner
//
//  Created by Kumar on 9/23/20.
//

import UIKit
import SwipeCellKit
import CoreData

class HikeListTableViewCell: SwipeTableViewCell {

    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var noItemsLabel: UILabel!
    @IBOutlet weak var completedImage: UIImageView!

    var existingHike : Hike?  {
        didSet {
            self.nameLabel.text = existingHike!.name
            self.descriptionLabel.text = existingHike!.desc
            self.noItemsLabel.text = String("(\(existingHike!.hikeGears.count))")
            self.completedImage.isHighlighted = existingHike!.completed
        }
    }

    // Core Data version
    var existingHikeCoreData: HikeEntity? {
        didSet {
            guard let hike = existingHikeCoreData else { return }
            self.nameLabel.text = hike.name
            self.descriptionLabel.text = hike.desc
            let count = (hike.hikeGears as? Set<HikeGearEntity>)?.count ?? 0
            self.noItemsLabel.text = String("(\(count))")
            self.completedImage.isHighlighted = hike.completed
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
