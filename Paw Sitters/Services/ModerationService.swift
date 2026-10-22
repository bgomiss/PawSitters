//
//  ModerationService.swift
//  Paw Sitters
//
//  Reporting objectionable content and blocking users.
//  Reports go to `reports` (write-only for users, reviewed by the team);
//  each user's block list lives in `blocks/{uid}.userIds`.
//

import FirebaseAuth
import FirebaseFirestore

enum ReportReason: String, CaseIterable, Identifiable {
    case spam = "Spam or scam"
    case inappropriate = "Inappropriate or offensive"
    case harassment = "Harassment or hate"
    case fake = "Fake listing or profile"
    case safety = "Animal welfare or safety concern"
    case other = "Something else"

    var id: String { rawValue }
}

enum ReportTarget {
    case listing(PetSittingListing)
    case user(id: String, name: String)
    case review(Review)

    var type: String {
        switch self {
        case .listing: return "listing"
        case .user: return "user"
        case .review: return "review"
        }
    }

    var targetId: String {
        switch self {
        case .listing(let listing): return listing.documentId
        case .user(let id, _): return id
        case .review(let review): return review.documentId
        }
    }

    /// The person responsible for the content (who can be blocked).
    var reportedUserId: String {
        switch self {
        case .listing(let listing): return listing.ownerId
        case .user(let id, _): return id
        case .review(let review): return review.reviewerId
        }
    }
}

class ModerationService: ObservableObject {
    private let db = Firestore.firestore()
    @Published private(set) var blockedIds: Set<String> = []
    private var listener: ListenerRegistration?

    func isBlocked(_ userId: String) -> Bool {
        blockedIds.contains(userId)
    }

    func startListening() {
        stopListening()
        guard let uid = Auth.auth().currentUser?.uid else { return }
        listener = db.collection("blocks").document(uid).addSnapshotListener { [weak self] snapshot, error in
            if let error = error {
                print("Failed to listen for blocked users: \(error.localizedDescription)")
                return
            }
            let ids = snapshot?.data()?["userIds"] as? [String] ?? []
            DispatchQueue.main.async { self?.blockedIds = Set(ids) }
        }
    }

    func stopListening() {
        listener?.remove()
        listener = nil
        blockedIds = []
    }

    func block(_ userId: String) {
        setBlocked(userId, blocked: true)
    }

    func unblock(_ userId: String) {
        setBlocked(userId, blocked: false)
    }

    private func setBlocked(_ userId: String, blocked: Bool) {
        guard let uid = Auth.auth().currentUser?.uid, !userId.isEmpty, userId != uid else { return }
        // Optimistic update; the listener reconciles with the server.
        if blocked { blockedIds.insert(userId) } else { blockedIds.remove(userId) }
        let change = blocked ? FieldValue.arrayUnion([userId]) : FieldValue.arrayRemove([userId])
        db.collection("blocks").document(uid).setData(["userIds": change], merge: true) { error in
            if let error = error {
                print("Failed to update blocked users: \(error.localizedDescription)")
            }
        }
    }

    func report(_ target: ReportTarget, reason: ReportReason, details: String,
                completion: @escaping (Error?) -> Void) {
        guard let uid = Auth.auth().currentUser?.uid else {
            completion(AppError.authError("You need to be signed in to report content."))
            return
        }
        db.collection("reports").addDocument(data: [
            "reporterId": uid,
            "targetType": target.type,
            "targetId": target.targetId,
            "reportedUserId": target.reportedUserId,
            "reason": reason.rawValue,
            "details": details,
            "status": "open",
            "createdAt": Timestamp(date: Date())
        ]) { error in
            DispatchQueue.main.async { completion(error) }
        }
    }
}
