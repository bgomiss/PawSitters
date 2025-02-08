//
//  NavigationPathManager.swift
//  Paw Sitters
//
//  Created by aycan duskun on 21.06.2024.
//

import SwiftUI

class NavigationPathManager: ObservableObject {
    @Published var path = NavigationPath()
        
    func push(_ destination: NavigationDestination) {
           path.append(destination)
       }
    
    func popToRoot() {
        path.removeLast(path.count)
    }
}
