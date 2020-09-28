//
//  EditHikeGearController.swift
//  PackPlanner
//
//  Created by Kumar on 9/27/20.
//

import UIKit
import ChameleonFramework

class EditHikeGearController: UIViewController {

    @IBOutlet weak var doneButton: UIBarButtonItem!
    
    var gear : Gear?
    var hikeGear : HikeGear? {
        didSet {
            self.gear = hikeGear!.gearList.first
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.doneButton.tintColor = .flatWhite()
        
        guard let navBar = navigationController?.navigationBar else { fatalError("Navigation controller does not exist.")
        }
        let navBarAppearance = UINavigationBarAppearance()
        navBarAppearance.configureWithOpaqueBackground()
        navBarAppearance.titleTextAttributes = [.foregroundColor: UIColor.white]
        navBarAppearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
        navBarAppearance.backgroundColor = .flatRedDark()
        
        navBar.standardAppearance = navBarAppearance
        navBar.scrollEdgeAppearance = navBarAppearance
        
        navBar.tintColor = .flatWhite()
        
        self.title = self.gear?.name
    }
    
    var delegate: RefreshProtocol?
    var indexPath: IndexPath?
    

    @IBAction func doneButtonPressed(_ sender: UIBarButtonItem) {
        _ = navigationController?.popViewController(animated: true)
        if (self.delegate != nil) {
            delegate?.refresh(at: self.indexPath!)
        }
    }
}
