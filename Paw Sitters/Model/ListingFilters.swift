//
//  ListingFilters.swift
//  Paw Sitters
//
//  Filters for the listings feed. They run on the listings already loaded in
//  the app, so results update instantly and Firestore needs no extra indexes.
//

import Foundation

struct ListingFilters: Equatable {
    var location = ""
    var dateRange: ClosedRange<Date>?
    var environment = ""

    /// Environment options shared by the filter sheet and the create-listing form.
    static let environments: [(name: String, icon: String)] = [
        ("Urban", "building.2.fill"),
        ("Suburban", "house.fill"),
        ("Countryside", "leaf.fill"),
        ("Rural", "carrot.fill"),
        ("Forestside", "tree.fill"),
        ("Mountainous", "mountain.2.fill"),
        ("Lakeside", "drop.fill"),
        ("Beachside", "beach.umbrella.fill"),
        ("Coastal", "water.waves"),
        ("Desert", "sun.haze.fill")
    ]

    static func icon(for environment: String) -> String {
        environments.first { $0.name == environment }?.icon ?? "leaf.fill"
    }

    /// City part of a location such as "Manisa, Manisa, Türkiye".
    static func city(from location: String) -> String {
        (location.split(separator: ",").first.map(String.init) ?? location)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    var trimmedLocation: String {
        location.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var activeCount: Int {
        (trimmedLocation.isEmpty ? 0 : 1) + (dateRange == nil ? 0 : 1) + (environment.isEmpty ? 0 : 1)
    }

    var isEmpty: Bool { activeCount == 0 }

    func matches(_ listing: PetSittingListing) -> Bool {
        if !trimmedLocation.isEmpty {
            // Compare city names only, so "Istanbul, Türkiye" matches a listing in "Istanbul".
            let wantedCity = Self.city(from: trimmedLocation)
            let listingCity = Self.city(from: listing.location ?? "")
            guard !listingCity.isEmpty,
                  listingCity.localizedCaseInsensitiveContains(wantedCity)
                    || wantedCity.localizedCaseInsensitiveContains(listingCity) else { return false }
        }
        if !environment.isEmpty, listing.environment != environment {
            return false
        }
        // Listings with flexible dates match any date range.
        if let wanted = dateRange, let offered = listing.dateRange, !offered.overlaps(wanted) {
            return false
        }
        return true
    }
}
