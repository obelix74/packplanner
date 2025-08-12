//
//  AddGearTableViewController.swift
//  PackPlanner
//
//  Created by Kumar on 9/21/20.
//

import UIKit
import Former
import RealmSwift
import SwiftUI

class AddGearViewController: FormViewController {
    
    @IBOutlet weak var saveButton: UIButton!
    
    var name : String?
    var desc : String?
    var weight : Double?
    var category : String?
    
    var existingGear : Gear?  {
        didSet {
            self.name = existingGear?.name
            self.desc = existingGear?.desc
            self.weight = existingGear?.weight()
            self.category = existingGear?.category
        }
    }
    
    let realm = try! Realm()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.rowHeight = 80.0

        configure()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        former.deselect(animated: true)
        
        let backgroundColor = UIColor.systemBackground
        saveButton.backgroundColor = backgroundColor
        saveButton.layer.cornerRadius = 10.0
        saveButton.tintColor = UIColor.systemRed
        
        guard let navBar = navigationController?.navigationBar else { fatalError("Navigation controller does not exist.")
        }
        let navBarAppearance = UINavigationBarAppearance()
        navBarAppearance.configureWithOpaqueBackground()
        navBarAppearance.titleTextAttributes = [.foregroundColor: UIColor.white]
        navBarAppearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
        navBarAppearance.backgroundColor = UIColor.systemRed
        
        navBar.standardAppearance = navBarAppearance
        navBar.scrollEdgeAppearance = navBarAppearance
        
        navBar.tintColor = UIColor.white
        
        self.title = existingGear?.name ?? "Add gear"
    }
    
    fileprivate func createTextField(_ nameOfTextField: String,
                                     text: String?,
                                     placeHolder: String,
                                     number: Bool,
                                     changedFunction: @escaping (String) -> Void) -> TextFieldRowFormer<FormTextFieldCell> {
        return TextFieldRowFormer<FormTextFieldCell>() {
            $0.titleLabel.text = nameOfTextField
            $0.titleLabel.textColor = .formerColor()
            $0.titleLabel.font = .boldSystemFont(ofSize: 16)
            $0.textField.textColor = .formerSubColor()
            $0.textField.font = .boldSystemFont(ofSize: 14)
            $0.textField.inputAccessoryView = self.inputAccessoryView
            $0.textField.returnKeyType = .next
            $0.tintColor = .formerColor()
            if (number) {
                $0.textField.keyboardType = .decimalPad
            }
        }.configure {
            $0.placeholder = placeHolder
            if (text != nil) {
                $0.text = text
            }
        }.onTextChanged { (text) in
            changedFunction(text)
        }
    }
    
    private func configure() {
        tableView.contentInset.bottom = 30
        
        // Create RowFormers
        let inputAccessoryView = FormerInputAccessoryView(former: former)
        
        let createSelectorRow = { (
            text: String,
            subText: String,
            onSelected: ((RowFormer) -> Void)?
        ) -> RowFormer in
            return LabelRowFormer<FormLabelCell>() {
                $0.titleLabel.textColor = .formerColor()
                $0.titleLabel.font = .boldSystemFont(ofSize: 16)
                $0.subTextLabel.textColor = .formerSubColor()
                $0.subTextLabel.font = .boldSystemFont(ofSize: 14)
                $0.accessoryType = .disclosureIndicator
            }.configure { form in
                _ = onSelected.map { form.onSelected($0) }
                form.text = text
                form.subText = subText
            }.onUpdate { (label) in
                self.category = label.subText
            }
        }
        
        let options = Categories.SINGLETON.list
        
        let selected : String = existingGear?.category ?? options[0]
        
        let pushSelectorRow = createSelectorRow("Category", selected, pushSelectorRowSelected(options: options))
        
        // Custom Input Accessory View Example
        
        let weightUnit = SettingsManager.SINGLETON.weightUnitString()
        
        let nameTextField = createTextField("Name", text: existingGear?.name, placeHolder: "Enter the name of this gear", number: false) { (text) in
            self.name = text
        }
        let descriptionTextField = createTextField("Description", text: existingGear?.desc, placeHolder: "Enter the description of this gear", number: false) { (text) in
            self.desc = text
        }
        
        let existingWeight = existingGear?.weight()
        var existingWeightString : String
        if (existingWeight != nil) {
            existingWeightString = String(format: "%.2f", existingWeight!)
        } else {
            existingWeightString = ""
        }
        
        let weightTextField = createTextField("Weight \(weightUnit)", text: existingWeightString, placeHolder: "Enter the weight of this gear in \(weightUnit)", number: true) { (text) in
            self.weight = Double(text)
        }
        
        // Create Headers and Footers
        
        let createHeader: ((String) -> ViewFormer) = { text in
            return LabelViewFormer<FormLabelHeaderView>()
                .configure {
                    $0.text = text
                    $0.viewHeight = 44
                }
        }
        
        // Create SectionFormers
        
        let categorySection = SectionFormer(rowFormer: pushSelectorRow)
            .set(headerViewFormer: createHeader("Choose a category where this belongs"))
        let textFieldsSection = SectionFormer(rowFormers: [nameTextField, descriptionTextField, weightTextField])
            .set(headerViewFormer: createHeader("Enter details for your gear here"))
        
        former.append(sectionFormer:
                        textFieldsSection, categorySection
        ).onCellSelected { _ in
            inputAccessoryView.update()
        }
    }
    
    @IBAction func saveButtonPressed(_ sender: UIButton) {
        if (self.name == nil || self.name!.isEmpty) {
            showAlert(name: "Name")
            return
        }
        
        if (self.weight == nil) {
            showAlert(name: "Weight")
            return
        }
        
        do {
            try realm.write {
                if let gear = existingGear {
                    gear.setValues(name: self.name!, desc: self.desc!, weight: self.weight!, category: self.category!)
                    
                } else {
                    let gear = Gear()
                    let desc = self.desc ?? ""
                    gear.setValues(name: self.name!, desc: desc, weight: self.weight!, category: self.category!)
                    realm.add(gear)
                }
            }
        } catch {
            print("Error adding gear \(error)")
        }
        
        _ = navigationController?.popViewController(animated: true)
    }
    
    // MARK: Private
    
    private func pushSelectorRowSelected(options: [String]) -> (RowFormer) -> Void {
        return { [weak self] rowFormer in
            if let rowFormer = rowFormer as? LabelRowFormer<FormLabelCell> {
                let controller = TextSelectorViewContoller()
                controller.texts = options
                controller.selectedText = rowFormer.subText
                controller.onSelected = {
                    rowFormer.subText = $0
                    rowFormer.update()
                }
                self?.navigationController?.pushViewController(controller, animated: true)
            }
        }
    }
    
    func showAlert(name: String) {
        let alert = UIAlertController(title: "Missing input", message: "\(name) is required", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Dismiss", style: .cancel, handler: nil))
        
        self.present(alert, animated: true)
    }
}
