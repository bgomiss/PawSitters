//
//  SideMenuOptionModel.swift
//  Paw Sitters
//
//  Created by aycan duskun on 14.09.2024.
//

import Foundation

enum SideMenuOptionModel: Int, CaseIterable {
    case date
    case location
    
    var title: String {
        switch self {
        case .date:
            return "Date"
        case .location:
            return "Location"
        }
    }
    
    var systemImageName: String {
        switch self {
        case .date:
            return "calendar"
        case .location:
            return "mappin.and.ellipse"
        }
    }
}

extension SideMenuOptionModel: Identifiable {
    var id: Int { return self.rawValue }
}
