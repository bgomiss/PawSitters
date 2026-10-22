//
//  City.swift
//  Paw Sitters
//
//  Created by aycan duskun on 29.07.2024.
//
import Foundation

struct City: Identifiable {
    let id = UUID()
    let name: String
    /// Region and country, e.g. "Manisa, Türkiye".
    var subtitle: String = ""
    
    /// Short name for display ("Manisa"), even when `name` is a full "City, Region, Country".
    var displayName: String {
        name.split(separator: ",").first.map { $0.trimmingCharacters(in: .whitespaces) } ?? name
    }
    
    /// Subtitle for display; falls back to the rest of `name` after the city.
    var displaySubtitle: String {
        if !subtitle.isEmpty { return subtitle }
        let parts = name.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        return parts.dropFirst().joined(separator: ", ")
    }
}
