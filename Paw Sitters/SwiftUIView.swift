//
//  SwiftUIView.swift
//  Paw Sitters
//
//  Created by aycan duskun on 19.08.2024.
//

//import SwiftUI
//
//struct ContentVview: View {
//    
//    var body: some View {
//        TabView {
//            Text("Home View")
//                .tabItem {
//                    Image(systemName: "house")
//                    Text("Home")
//                }
//            
//            Text("Search View")
//                .tabItem {
//                    Image(systemName: "magnifyingglass")
//                    Text("Search")
//                }
//            
//            Text("Profile View")
//                .tabItem {
//                    Image(systemName: "person")
//                    Text("Profile")
//                }
//        }
//    }
//}
//
//struct ContentVview_Previews: PreviewProvider {
//    static var previews: some View {
//        ContentVview()
//    }
//}
import SwiftUI

struct ContentVview: View {
    @State private var selectedTab = 0

    var body: some View {
        VStack {
            Picker("Options", selection: $selectedTab) {
                Text("Home").tag(0)
                Text("Search").tag(1)
                //Text("Profile").tag(2)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding()

            Spacer()

            if selectedTab == 0 {
                Text("Home View")
            } else if selectedTab == 1 {
                Text("Search View")
            } else if selectedTab == 2 {
                Text("Profile View")
            }

            Spacer()
        }
    }
}

struct ContentVview_Previews: PreviewProvider {
    static var previews: some View {
        ContentVview()
    }
}

