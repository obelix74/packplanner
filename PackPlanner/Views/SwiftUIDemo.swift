//
//  SwiftUIDemo.swift
//  PackPlanner
//
//  Created by Claude on SwiftUI Migration
//

import SwiftUI

struct SwiftUIDemo: View {
    var body: some View {
        VStack {
            Text("SwiftUI Demo")
                .font(.title)
                .padding()
            
            Text("PackPlanner SwiftUI Integration Working!")
                .foregroundColor(.blue)
                .padding()
            
            Spacer()
        }
    }
}

#if DEBUG
struct SwiftUIDemo_Previews: PreviewProvider {
    static var previews: some View {
        SwiftUIDemo()
    }
}
#endif