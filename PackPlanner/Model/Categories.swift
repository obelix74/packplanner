//
//  Categories.swift
//  PackPlanner
//
//  Created by Kumar on 9/20/20.
//

import Foundation

class Categories {
    
    static let SINGLETON : Categories = Categories()
    
    var list: [String] = []
    
    private init() {
        list.append("Backpack")
        list.append("Clothing")
        list.append("Containers")
        list.append("Cooking")
        list.append("Electronics")
        list.append("Emergency")
        list.append("Extras")
        list.append("First Aid")
        list.append("Food")
        list.append("Footwear")
        list.append("Hiking Tools")
        list.append("Hydration")
        list.append("Hygiene")
        list.append("Navigation")
        list.append("Personal Items")
        list.append("Sacks")
        list.append("Shelter")
        list.append("Sleep System")
        list.append("Survival")
        list.append("Tools")
        list.append("Uncategorized")
        list.append("Water")
    }
}
