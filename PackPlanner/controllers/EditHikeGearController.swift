//
//  EditHikeGearController.swift
//  PackPlanner
//
//  Created by Kumar on 9/27/20.
//

import UIKit

class EditHikeGearController: UIViewController {

    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var weightLabel: UILabel!
    @IBOutlet weak var quantityLabel: UILabel!
    @IBOutlet weak var quantityStepper: UIStepper!
    @IBOutlet weak var doneButton: UIButton!
    
    var gear : Gear?
    var hikeGear : HikeGear? {
        didSet {
            self.gear = hikeGear!.gear
        }
    }
    var hikeBrain : HikeBrain?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let backgroundColor = UIColor.systemRed
        doneButton.backgroundColor = backgroundColor
        doneButton.layer.cornerRadius = 25.0
        doneButton.tintColor = UIColor.white
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.title = self.gear?.name
        updateLabels()
    }
    
    var delegate: RefreshProtocol?
    var indexPath: IndexPath?
    
    func updateLabels() {
        self.nameLabel.text = self.gear?.name
        self.descriptionLabel.text = self.gear?.desc
        self.weightLabel.text = self.gear?.weightString()
        self.quantityStepper.value = Double(self.hikeGear!.numberUnits)
        self.quantityLabel.text = String(format: "%.0f", self.quantityStepper.value)
    }
    
    
    @IBAction func doneButtonPressed(_ sender: UIButton) {
        if (self.delegate != nil) {
            delegate?.refresh(at: self.indexPath!)
        }
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func quantityStepperSelected(_ sender: UIStepper) {
        let number = Int(sender.value)
        self.hikeBrain!.setNumber(hikeGear: self.hikeGear!, number: number)
        self.quantityLabel.text = String(number)
    }
}
