//
//  ReviewService.swift
//  Paw Sitters
//
//  Writes reviews for accepted applications and loads (and caches) the
//  reviews a user has received.
//

import FirebaseAuth
import FirebaseFirestore

class ReviewService: ObservableObject {
    private let db = Firestore.firestore()
    /// Reviews received, keyed by the reviewed user's ID.
    @Published private(set) var reviewsByUser: [String: [Review]] = [:]
    /// Application IDs the signed-in user has already reviewed.
    @Published private(set) var reviewedApplicationIds: Set<String> = []

    private var writtenListener: ListenerRegistration?
    private var loading: Set<String> = []

    func reviews(for userId: String) -> [Review] {
        reviewsByUser[userId] ?? []
    }

    func summary(for userId: String) -> RatingSummary {
        RatingSummary(reviews: reviews(for: userId))
    }

    func hasReviewed(_ application: Application) -> Bool {
        reviewedApplicationIds.contains(application.documentId)
    }

    func startListening() {
        stopListening()
        guard let uid = Auth.auth().currentUser?.uid else { return }
        writtenListener = db.collection("reviews")
            .whereField("reviewerId", isEqualTo: uid)
            .addSnapshotListener { [weak self] snapshot, error in
                if let error = error {
                    print("Failed to listen for written reviews: \(error.localizedDescription)")
                    return
                }
                let ids = Set((snapshot?.documents ?? []).compactMap { $0.data()["applicationId"] as? String })
                DispatchQueue.main.async { self?.reviewedApplicationIds = ids }
            }
    }

    func stopListening() {
        writtenListener?.remove()
        writtenListener = nil
        reviewedApplicationIds = []
        reviewsByUser = [:]
        loading = []
    }

    /// Loads the reviews a user has received. Cached unless `force` is set.
    func loadReviews(for userId: String, force: Bool = false) {
        guard !userId.isEmpty, !loading.contains(userId), force || reviewsByUser[userId] == nil else { return }
        loading.insert(userId)
        db.collection("reviews")
            .whereField("revieweeId", isEqualTo: userId)
            .getDocuments { [weak self] snapshot, error in
                DispatchQueue.main.async {
                    self?.loading.remove(userId)
                    if let error = error {
                        print("Failed to load reviews: \(error.localizedDescription)")
                        return
                    }
                    self?.reviewsByUser[userId] = (snapshot?.documents ?? [])
                        .map { Review(documentId: $0.documentID, data: $0.data()) }
                        .sorted { $0.createdAt.dateValue() > $1.createdAt.dateValue() }
                }
            }
    }

    /// Reviews the other party of an accepted application.
    func submitReview(for application: Application, reviewerName: String, rating: Int, comment: String,
                      completion: @escaping (Error?) -> Void) {
        guard let uid = Auth.auth().currentUser?.uid else {
            completion(AppError.authError("You need to be signed in to leave a review."))
            return
        }
        let revieweeId = uid == application.applicantId ? application.listingOwnerId : application.applicantId
        let data: [String: Any] = [
            "applicationId": application.documentId,
            "listingId": application.listingId,
            "listingTitle": application.listingTitle,
            "reviewerId": uid,
            "reviewerName": reviewerName,
            "revieweeId": revieweeId,
            "rating": rating,
            "comment": comment,
            "createdAt": Timestamp(date: Date())
        ]
        db.collection("reviews").document("\(application.documentId)_\(uid)").setData(data) { [weak self] error in
            DispatchQueue.main.async {
                if error == nil {
                    self?.reviewedApplicationIds.insert(application.documentId)
                    self?.loadReviews(for: revieweeId, force: true)
                }
                completion(error)
            }
        }
    }
}
