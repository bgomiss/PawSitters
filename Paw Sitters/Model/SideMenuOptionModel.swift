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
    case environment
    
    var title: String {
        switch self {
        case .date:
            return "Date"
        case .location:
            return "Location"
        case .environment:
            return "Environment"
        }
    }
    
    var systemImageName: String {
        switch self {
        case .date:
            return "calendar"
        case .location:
            return "mappin.and.ellipse"
        case .environment:
            return "leaf"
        }
    }
    
    
    func chevronImageName(isSelected: Bool) -> String {
        switch self {
        case .date:
            return isSelected ? "chevron.up" : "chevron.down"
        case .location:
            return isSelected ? "chevron.up" : "chevron.down"
        case .environment:
            return isSelected ? "chevron.up" : "chevron.down"
        
        }
    }
}

extension SideMenuOptionModel: Identifiable {
    var id: Int { return self.rawValue }
}
