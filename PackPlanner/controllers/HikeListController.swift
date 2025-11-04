//
//  HikeListController.swift
//  PackPlanner
//
//  DEPRECATED: Legacy UIKit controller replaced by HikeListView (SwiftUI)
//

import UIKit

class HikeListController: UITableViewController {
    // Legacy storyboard outlets - kept to prevent crashes
    @IBOutlet weak var addButton: UIBarButtonItem?
    @IBOutlet weak var searchBar: UISearchBar?

    override func viewDidLoad() {
        super.viewDidLoad()
        print("⚠️ HikeListController is deprecated. Use SwiftUI HikeListView instead.")
    }
}
