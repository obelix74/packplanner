//
//  HikeListView.swift
//  PackPlanner
//
//  Created by Claude on SwiftUI Migration
//

import SwiftUI

struct HikeListView: View {
    var body: some View {
        NavigationView {
            VStack {
                Text("Hike List")
                    .font(.title)
                    .padding()
                
                Text("SwiftUI View Stub")
                    .foregroundColor(.orange)
                    .padding()
                
                Spacer()
            }
            .navigationTitle("Hikes")
        }
    }
}

#if DEBUG
struct HikeListView_Previews: PreviewProvider {
    static var previews: some View {
        HikeListView()
    }
}
#endif