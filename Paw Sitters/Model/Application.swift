//
//  Application.swift
//  Paw Sitters
//
//  A request to take part in a listing (e.g. a sitter applying to an owner's
//  pet-sitting request). Stored in the top-level `applications` collection.
//

import FirebaseFirestore

enum ApplicationStatus: String, CaseIterable {
    case pending, accepted, declined, withdrawn

    var title: String {
        switch self {
        case .pending: return "Pending"
        case .accepted: return "Accepted"
        case .declined: return "Declined"
        case .withdrawn: return "Withdrawn"
        }
    }

    var icon: String {
        switch self {
        case .pending: return "hourglass"
        case .accepted: return "checkmark.seal.fill"
        case .declined: return "xmark.circle.fill"
        case .withdrawn: return "arrow.uturn.backward.circle.fill"
        }
    }
}

struct Application: Identifiable, Hashable {
    var id: String { documentId }
    let documentId: String
    let listingId: String
    let listingTitle: String
    let listingOwnerId: String
    let listingOwnerName: String
    let applicantId: String
    let applicantName: String
    let message: String
    let status: ApplicationStatus
    let createdAt: Timestamp
    let updatedAt: Timestamp

    init(documentId: String, data: [String: Any]) {
        self.documentId = documentId
        self.listingId = data["listingId"] as? String ?? ""
        self.listingTitle = data["listingTitle"] as? String ?? ""
        self.listingOwnerId = data["listingOwnerId"] as? String ?? ""
        self.listingOwnerName = data["listingOwnerName"] as? String ?? ""
        self.applicantId = data["applicantId"] as? String ?? ""
        self.applicantName = data["applicantName"] as? String ?? ""
        self.message = data["message"] as? String ?? ""
        self.status = ApplicationStatus(rawValue: data["status"] as? String ?? "") ?? .pending
        self.createdAt = data["createdAt"] as? Timestamp ?? Timestamp(date: Date())
        self.updatedAt = data["updatedAt"] as? Timestamp ?? self.createdAt
    }
}
