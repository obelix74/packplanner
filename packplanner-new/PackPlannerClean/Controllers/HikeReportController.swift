//
//  HikeReportControllerViewController.swift
//  PackPlanner
//
//  Created by Kumar on 9/28/20.
//

import UIKit
import ChameleonFramework

class HikeReportController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var pickerView: UIPickerView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var dismissButton: UIButton!
    
    let filter = ["Total weight","Base weight","Consumable weight","Worn weight"]
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var sumLabel: UILabel!
    
    var hikeBrain : HikeBrain?
    
    var reportData : [String : Double] = [:]
    var sortedKeys : [String] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let backgroundColor = UIColor.flatRedDark()
        dismissButton.backgroundColor = backgroundColor
        dismissButton.layer.cornerRadius = 25.0
        dismissButton.tintColor = ContrastColorOf(backgroundColor, returnFlat: true)
        
        self.pickerView.delegate = self
        self.pickerView.dataSource = self
        
        self.tableView.delegate = self
        self.tableView.dataSource = self
        
        let selectedRow = self.pickerView.selectedRow(inComponent: 0)
        print("Default selectedRow \(selectedRow)")
        
        self.reportData = self.hikeBrain!.totalWeightDistribution
        self.sortedKeys = reportData.keys.sorted()
        self.titleLabel.text = filter[0]
        self.sumLabel.text = self.hikeBrain!.getTotalWeight()
        self.tableView.reloadData()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.reportData.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "reportCell", for: indexPath) as! ReportTableCell
        let category = self.sortedKeys[indexPath.row]
        let weight = self.reportData[category]
        cell.categoryLabel.text = category
        cell.weightLabel.text = Gear.getWeightString(weight: weight!)
        return cell
    }
    
    @IBAction func dismissButtonSelected(_ sender: UIButton) {
        dismiss(animated: true, completion: nil)
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
        
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return filter.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return filter[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if (row == 0) {
            self.reportData = self.hikeBrain!.totalWeightDistribution
            self.sumLabel.text = self.hikeBrain!.getTotalWeight()
        }
        else if (row == 1) {
            self.reportData = self.hikeBrain!.baseWeightDistribution
            self.sumLabel.text = self.hikeBrain!.getBaseWeight()
        }
        else if (row == 2) {
            self.reportData = self.hikeBrain!.consumableWeightDistribution
            self.sumLabel.text = self.hikeBrain!.getConsumableWeight()
        }
        else if (row == 3) {
            self.reportData = self.hikeBrain!.wornWeightDistribution
            self.sumLabel.text = self.hikeBrain!.getWornWeight()
        }
        self.titleLabel.text = self.filter[row]
        self.sortedKeys = self.reportData.keys.sorted()
        self.tableView.reloadData()
    }
    
}
