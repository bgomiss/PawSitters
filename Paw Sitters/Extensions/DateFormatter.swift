//
//  DateFormatter.swift
//  Paw Sitters
//
//  Created by aycan duskun on 23.07.2024.
//

import Foundation

extension DateFormatter {
    static var shortDate: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter
    }
}

