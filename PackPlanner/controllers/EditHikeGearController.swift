//
//  EditHikeGearController.swift
//  PackPlanner
//
//  Created by Kumar on 9/27/20.
//

import UIKit

class EditHikeGearController: UIViewController {

    @IBOutlet weak var doneButton: UIBarButtonItem!
    var hikeGear : HikeGear? {
        didSet {
            
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

    @IBAction func doneButtonPressed(_ sender: UIBarButtonItem) {
        _ = navigationController?.popViewController(animated: true)
    }
}
