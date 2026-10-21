//
//  ApplicationService.swift
//  Paw Sitters
//
//  Sends applications to listings and keeps the signed-in user's sent and
//  received applications up to date.
//

import FirebaseAuth
import FirebaseFirestore

class ApplicationService: ObservableObject {
    private let db = Firestore.firestore()
    /// Applications the signed-in user has sent to other people's listings.
    @Published var sent: [Application] = []
    /// Applications other people have sent to the signed-in user's listings.
    @Published var received: [Application] = []

    private var sentListener: ListenerRegistration?
    private var receivedListener: ListenerRegistration?

    var pendingReceivedCount: Int {
        received.filter { $0.status == .pending }.count
    }

    /// The signed-in user's latest application to a listing, if any.
    func application(for listing: PetSittingListing) -> Application? {
        sent.first { $0.listingId == listing.documentId }
    }

    func startListening() {
        stopListening()
        guard let uid = Auth.auth().currentUser?.uid else { return }
        // Single-field filters only, sorted on the client, so no composite index is needed.
        sentListener = db.collection("applications")
            .whereField("applicantId", isEqualTo: uid)
            .addSnapshotListener { [weak self] snapshot, error in
                self?.handle(snapshot, error: error) { self?.sent = $0 }
            }
        receivedListener = db.collection("applications")
            .whereField("listingOwnerId", isEqualTo: uid)
            .addSnapshotListener { [weak self] snapshot, error in
                self?.handle(snapshot, error: error) { self?.received = $0 }
            }
    }

    func stopListening() {
        sentListener?.remove()
        receivedListener?.remove()
        sentListener = nil
        receivedListener = nil
        sent = []
        received = []
    }

    private func handle(_ snapshot: QuerySnapshot?, error: Error?, assign: @escaping ([Application]) -> Void) {
        if let error = error {
            print("Failed to listen for applications: \(error.localizedDescription)")
            return
        }
        let applications = (snapshot?.documents ?? [])
            .map { Application(documentId: $0.documentID, data: $0.data()) }
            .sorted { $0.updatedAt.dateValue() > $1.updatedAt.dateValue() }
        DispatchQueue.main.async { assign(applications) }
    }

    func apply(to listing: PetSittingListing, applicantName: String, message: String, completion: @escaping (Error?) -> Void) {
        guard let uid = Auth.auth().currentUser?.uid else {
            completion(AppError.authError("You need to be signed in to apply."))
            return
        }
        let now = Timestamp(date: Date())
        let data: [String: Any] = [
            "listingId": listing.documentId,
            "listingTitle": listing.title,
            "listingOwnerId": listing.ownerId,
            "listingOwnerName": listing.name,
            "applicantId": uid,
            "applicantName": applicantName,
            "message": message,
            "status": ApplicationStatus.pending.rawValue,
            "createdAt": now,
            "updatedAt": now
        ]
        // One application per user and listing: a deterministic ID makes re-applying overwrite it.
        db.collection("applications").document("\(listing.documentId)_\(uid)").setData(data) { error in
            DispatchQueue.main.async { completion(error) }
        }
    }

    func updateStatus(of application: Application, to status: ApplicationStatus, completion: ((Error?) -> Void)? = nil) {
        db.collection("applications").document(application.documentId).updateData([
            "status": status.rawValue,
            "updatedAt": Timestamp(date: Date())
        ]) { error in
            if let error = error {
                print("Failed to update application: \(error.localizedDescription)")
            }
            DispatchQueue.main.async { completion?(error) }
        }
    }
}
