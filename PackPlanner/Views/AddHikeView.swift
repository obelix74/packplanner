//
//  AddHikeView.swift
//  PackPlanner
//
//  Created by Claude on SwiftUI Migration
//

import SwiftUI

struct AddHikeView: View {
    let hike: HikeSwiftUI?
    
    init(hike: HikeSwiftUI? = nil) {
        self.hike = hike
    }
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Add/Edit Hike")
                    .font(.title)
                    .padding()
                
                Text("SwiftUI View Stub")
                    .foregroundColor(.orange)
                    .padding()
                
                Spacer()
            }
            .navigationTitle("Add Hike")
        }
    }
}

#if DEBUG
struct AddHikeView_Previews: PreviewProvider {
    static var previews: some View {
        AddHikeView()
    }
}
#endif