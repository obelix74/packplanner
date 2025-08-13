//
//  HikeDetailView.swift
//  PackPlanner
//
//  Created by Claude on SwiftUI Migration
//

import SwiftUI

struct HikeDetailView: View {
    let hike: HikeSwiftUI
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Hike Detail")
                    .font(.title)
                    .padding()
                
                Text("SwiftUI View Stub")
                    .foregroundColor(.orange)
                    .padding()
                
                Spacer()
            }
            .navigationTitle("Hike Detail")
        }
    }
}

#if DEBUG
struct HikeDetailView_Previews: PreviewProvider {
    static var previews: some View {
        HikeDetailView(hike: HikeSwiftUI())
    }
}
#endif