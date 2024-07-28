//
//  PetSittingListing.swift
//  Paw Sitters
//
//  Created by aycan duskun on 21.06.2024.
//

import FirebaseFirestoreSwift
import Foundation

struct PetSittingListing: Codable, Identifiable {
    @DocumentID var id: String?
    var title: String
    var description: String
    var name: String
    var dateRange: ClosedRange<Date>?
    var imageUrl: String?
    var imageUrls: [String]?
    var role: String
    var location: String?
    var ownerId: String
}

