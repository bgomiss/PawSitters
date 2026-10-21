//
//  Review.swift
//  Paw Sitters
//
//  A rating and comment one party of an accepted application leaves about
//  the other. Stored in `reviews` with the ID "{applicationId}_{reviewerId}",
//  so each person can review a given stay only once.
//

import FirebaseFirestore

struct Review: Identifiable, Hashable {
    var id: String { documentId }
    let documentId: String
    let applicationId: String
    let listingId: String
    let listingTitle: String
    let reviewerId: String
    let reviewerName: String
    let revieweeId: String
    let rating: Int
    let comment: String
    let createdAt: Timestamp

    init(documentId: String, data: [String: Any]) {
        self.documentId = documentId
        self.applicationId = data["applicationId"] as? String ?? ""
        self.listingId = data["listingId"] as? String ?? ""
        self.listingTitle = data["listingTitle"] as? String ?? ""
        self.reviewerId = data["reviewerId"] as? String ?? ""
        self.reviewerName = data["reviewerName"] as? String ?? ""
        self.revieweeId = data["revieweeId"] as? String ?? ""
        self.rating = (data["rating"] as? Int) ?? Int(data["rating"] as? Int64 ?? 0)
        self.comment = data["comment"] as? String ?? ""
        self.createdAt = data["createdAt"] as? Timestamp ?? Timestamp(date: Date())
    }
}

/// Average rating and number of reviews for one user.
struct RatingSummary: Equatable {
    let average: Double
    let count: Int

    static let empty = RatingSummary(average: 0, count: 0)

    init(average: Double, count: Int) {
        self.average = average
        self.count = count
    }

    init(reviews: [Review]) {
        count = reviews.count
        average = reviews.isEmpty ? 0 : Double(reviews.map(\.rating).reduce(0, +)) / Double(reviews.count)
    }
}
