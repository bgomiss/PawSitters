//
//  FirestoreService.swift
//  Paw Sitters
//
//  Created by aycan duskun on 21.06.2024.
//

import FirebaseFirestore
import FirebaseStorage
import FirebaseFirestoreSwift
import Firebase

class FirestoreService: ObservableObject {
    private var db = Firestore.firestore()
    @Published var listings: [PetSittingListing] = []
    @Published var filteredListings: [PetSittingListing] = []
    /// IDs of the listings the signed-in user has favorited (stored per user in `favorites/{uid}`).
    @Published var favoriteIds: Set<String> = []
    var listener: ListenerRegistration?
    private var favoritesListener: ListenerRegistration?
    var userProfileService: UserProfileService?
    
//    func fetchListings(for role: String, completion: @escaping (Result<[PetSittingListing], Error>) -> Void) {
//        guard let userID = Auth.auth().currentUser?.uid else { return }
//        let collection = role == "Sitter" ? "ownersListings" : "sittersListings"
//        db.collection(collection).getDocuments { (querySnapshot, error) in
//            if let error = error {
//                completion(.failure(error))
//            } else {
//                let listings = querySnapshot?.documents.compactMap { document in
//                    try? document.data(as: PetSittingListing.self)
//                } ?? []
//                completion(.success(listings))
//                print(listings)
//            }
//        }
//    }
    @MainActor
    func fetchListings(for role: String, location: String? = nil, dateRange: ClosedRange<Date>? = nil, environment: String? = nil) {
        // Remove previous listener
        listener?.remove()
        
        // Clear existing listings
        listings.removeAll()
        filteredListings.removeAll()
        
        let collection = role == "Sitter" ? "ownersListings" : "sittersListings"
        var query: Query = db.collection(collection)
        
        // Add filters
        if let location = location, !location.isEmpty {
            query = query.whereField("location", isEqualTo: location)
        }
        
        if let environment = environment, !environment.isEmpty {
            query = query.whereField("environment", isEqualTo: environment)
        }
        
        if let dateRange = dateRange {
            query = query
                .whereField("dateRange.start", isLessThanOrEqualTo: Timestamp(date: dateRange.upperBound))
                .whereField("dateRange.end", isGreaterThanOrEqualTo: Timestamp(date: dateRange.lowerBound))
                .order(by: "dateRange.start", descending: false)
        } else {
            query = query.order(by: "timestamp", descending: false)
        }
        
        // Attach snapshot listener
        listener = query.addSnapshotListener { [weak self] querySnapshot, error in
            guard let self = self else { return }
            
            if let error = error {
                print("Failed to listen for listings: \(error.localizedDescription)")
                return
            }
            
            let changes = querySnapshot?.documentChanges ?? []
            
            // Process changes on main thread
            DispatchQueue.main.async {
                for change in changes {
                    let docId = change.document.documentID
                    let data = change.document.data()
                    
                    switch change.type {
                    case .added:
                        if !self.filteredListings.contains(where: { $0.documentId == docId }) {
                            let newListing = PetSittingListing(documentId: docId, data: data)
                            self.filteredListings.append(newListing)
                            self.listings.append(newListing)
                        }
                    case .modified:
                        if let index = self.filteredListings.firstIndex(where: { $0.documentId == docId }) {
                            let updatedListing = PetSittingListing(documentId: docId, data: data)
                            self.filteredListings[index] = updatedListing
                            if let listingIndex = self.listings.firstIndex(where: { $0.documentId == docId }) {
                                self.listings[listingIndex] = updatedListing
                            }
                        }
                    case .removed:
                        self.filteredListings.removeAll { $0.documentId == docId }
                        self.listings.removeAll { $0.documentId == docId }
                    }
                }
            }
        }
    }
//    func fetchListings(for role: String) {
//        guard let _ = Auth.auth().currentUser?.uid else { return }
//        let collection = role == "Sitter" ? "ownersListings" : "sittersListings"
//        
//        self.listings.removeAll()
//        
//        db.collection(collection)
//            .order(by: "timestamp", descending: false)
//            .addSnapshotListener { querySnapshot, error in
//                if let error = error {
//                    print("FAILED TO LISTEN FOR LISTINGS: \(error.localizedDescription)")
//                    return
//                }
//                
//                DispatchQueue.main.async {
//                    querySnapshot?.documentChanges.forEach({ change in
//                        let docId = change.document.documentID
//                        let data = change.document.data()
//                        
//                        switch change.type {
//                        case .added:
//                            if !self.listings.contains(where: { $0.documentId == docId }) {
//                                let newListing = PetSittingListing(documentId: docId, data: data)
//                                    self.listings.append(newListing)
//                                }
//                        case .removed:
//                            self.listings.removeAll { $0.documentId == docId }
//                        default:
//                            break
//                        }
//                    })
//                }
//            }
//    }
    
    func fetchByLocation(for role: String, location: String?) {
        guard let _ = Auth.auth().currentUser?.uid else { return }
        let collection = role == "Sitter" ? "ownersListings" : "sittersListings"
        
        self.filteredListings.removeAll()
        
        db.collection(collection)
            .whereField("location", isEqualTo: location ?? "")
            .order(by: "timestamp", descending: false)
                    .addSnapshotListener { querySnapshot, error in
                        if let error = error {
                            print("FAILED TO LISTEN FOR LISTINGS: \(error.localizedDescription)")
                            return
                        }
                        
                        DispatchQueue.main.async {
                            querySnapshot?.documentChanges.forEach({ change in
                                let docId = change.document.documentID
                                let data = change.document.data()
                                
                                switch change.type {
                                case .added:
                                    if !self.filteredListings.contains(where: { $0.documentId == docId }) {
                                        let newListing = PetSittingListing(documentId: docId, data: data)
                                        self.filteredListings.append(newListing)
                                    }
                                case .removed:
                                    self.filteredListings.removeAll { $0.documentId == docId }
                                default:
                                    break
                                }
                            })
                        }
                    }
            }
    
    func fetchByEnvironment(for role: String, environment: String?) {
        guard let _ = Auth.auth().currentUser?.uid else { return }
        let collection = role == "Sitter" ? "ownersListings" : "sittersListings"
        
        self.filteredListings.removeAll()
        
        db.collection(collection)
            .whereField("environment", isEqualTo: environment ?? "")
            .order(by: "timestamp", descending: false)
                    .addSnapshotListener { querySnapshot, error in
                        if let error = error {
                            print("FAILED TO LISTEN FOR LISTINGS: \(error.localizedDescription)")
                            return
                        }
                        
                        DispatchQueue.main.async {
                            querySnapshot?.documentChanges.forEach({ change in
                                let docId = change.document.documentID
                                let data = change.document.data()
                                
                                switch change.type {
                                case .added:
                                    if !self.filteredListings.contains(where: { $0.documentId == docId }) {
                                        let newListing = PetSittingListing(documentId: docId, data: data)
                                        self.filteredListings.append(newListing)
                                    }
                                case .removed:
                                    self.filteredListings.removeAll { $0.documentId == docId }
                                default:
                                    break
                                }
                            })
                        }
                    }
            }

    func fetchByDateRange(for role: String, dateRange: ClosedRange<Date>) {
            guard let _ = Auth.auth().currentUser?.uid else { return }
            let collection = role == "Sitter" ? "ownersListings" : "sittersListings"
            
            self.filteredListings.removeAll()
        // Tarihlerin saat bileşenlerini sıfırla
           // let adjustedDateRange = resetTime(dateRange: dateRange)
        
            db.collection(collection)
                .whereField("dateRange.start", isLessThanOrEqualTo: Timestamp(date: dateRange.upperBound))
                .whereField("dateRange.end", isGreaterThanOrEqualTo: Timestamp(date: dateRange.lowerBound))
                .order(by: "dateRange.start", descending: false)
                .addSnapshotListener { querySnapshot, error in
                    if let error = error {
                        print("Error getting documents: \(error)")
                        return
                    }
                    
                    DispatchQueue.main.async {
                        querySnapshot?.documentChanges.forEach({ change in
                            let docId = change.document.documentID
                            let data = change.document.data()
                            
                            switch change.type {
                            case .added:
                                if !self.filteredListings.contains(where: { $0.documentId == docId }) {
                                    let newListing = PetSittingListing(documentId: docId, data: data)
                                    self.filteredListings.append(newListing)
                                }
                            case .removed:
                                self.filteredListings.removeAll { $0.documentId == docId }
                            default:
                                break
                            }
                        })
                    }
                }
        }
    
    func fetchByLocationAndDateRange(for role: String, location: String?, dateRange: ClosedRange<Date>) {
        guard let _ = Auth.auth().currentUser?.uid else { return }
        let collection = role == "Sitter" ? "ownersListings" : "sittersListings"
        
        self.filteredListings.removeAll()
        
        db.collection(collection)
            .whereField("location", isEqualTo: location ?? "")
            .whereField("dateRange.start", isLessThanOrEqualTo: Timestamp(date: dateRange.upperBound))
            .whereField("dateRange.end", isGreaterThanOrEqualTo: Timestamp(date: dateRange.lowerBound))
            .order(by: "dateRange.start", descending: false)
            .addSnapshotListener { querySnapshot, error in
                if let error = error {
                    print("Error getting documents: \(error)")
                    return
                }
                
                DispatchQueue.main.async {
                    querySnapshot?.documentChanges.forEach({ change in
                        let docId = change.document.documentID
                        let data = change.document.data()
                        
                        switch change.type {
                        case .added:
                            if !self.filteredListings.contains(where: { $0.documentId == docId }) {
                                let newListing = PetSittingListing(documentId: docId, data: data)
                                self.filteredListings.append(newListing)
                            }
                        case .removed:
                            self.filteredListings.removeAll { $0.documentId == docId }
                        default:
                            break
                        }
                    })
                }
            }
    }

    
        
    func addListing(_ role: String, listingData: [String : Any], completion: @escaping (Result<Void, Error>) -> Void) {
        let collection = role == "Sitter" ? "sittersListings" : "ownersListings"
        let document = db.collection(collection).document() // Belge ID'sini otomatik oluşturur
        document.setData(listingData) { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }
    
    // MARK: - The signed-in user's own listings
    
    /// Listings the signed-in user published (sitters publish to `sittersListings`,
    /// owners to `ownersListings`; the feed only shows the other side's listings).
    @Published var myListings: [PetSittingListing] = []
    private var myListingsListener: ListenerRegistration?
    
    static func listingsCollection(forAuthorRole role: String) -> String {
        role == "Sitter" ? "sittersListings" : "ownersListings"
    }
    
    func listenToMyListings(role: String) {
        myListingsListener?.remove()
        guard let uid = Auth.auth().currentUser?.uid else { return }
        myListingsListener = db.collection(Self.listingsCollection(forAuthorRole: role))
            .whereField("ownerId", isEqualTo: uid)
            .addSnapshotListener { [weak self] snapshot, error in
                if let error = error {
                    print("Failed to listen for own listings: \(error.localizedDescription)")
                    return
                }
                let listings = (snapshot?.documents ?? [])
                    .map { PetSittingListing(documentId: $0.documentID, data: $0.data()) }
                    .sorted { $0.timestamp.dateValue() > $1.timestamp.dateValue() }
                DispatchQueue.main.async { self?.myListings = listings }
            }
    }
    
    func updateListing(_ listing: PetSittingListing, role: String, fields: [String: Any]) async throws {
        try await db.collection(Self.listingsCollection(forAuthorRole: role))
            .document(listing.documentId)
            .updateData(fields)
    }
    
    /// Deletes a listing and its photos, and closes its pending applications.
    func deleteListing(_ listing: PetSittingListing, role: String) async throws {
        try await db.collection(Self.listingsCollection(forAuthorRole: role)).document(listing.documentId).delete()
        for url in listing.imageUrls ?? [] where url.contains("firebasestorage") {
            try? await Storage.storage().reference(forURL: url).delete()
        }
        if let uid = Auth.auth().currentUser?.uid {
            let pending = try? await db.collection("applications")
                .whereField("listingOwnerId", isEqualTo: uid)
                .whereField("listingId", isEqualTo: listing.documentId)
                .getDocuments()
            for document in pending?.documents ?? [] where document.data()["status"] as? String == "pending" {
                try? await document.reference.updateData(["status": "declined", "updatedAt": Timestamp(date: Date())])
            }
        }
    }
    
    func isFavorite(_ listing: PetSittingListing) -> Bool {
        favoriteIds.contains(listing.documentId)
    }
    
    func listenToFavorites() {
        favoritesListener?.remove()
        guard let uid = Auth.auth().currentUser?.uid else { return }
        favoritesListener = db.collection("favorites").document(uid).addSnapshotListener { [weak self] snapshot, error in
            if let error = error {
                print("Failed to listen for favorites: \(error.localizedDescription)")
                return
            }
            let ids = snapshot?.data()?["listingIds"] as? [String] ?? []
            DispatchQueue.main.async {
                self?.favoriteIds = Set(ids)
            }
        }
    }
    
    func toggleFavorite(_ listing: PetSittingListing) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let listingId = listing.documentId
        let willBeFavorite = !favoriteIds.contains(listingId)
        
        // Optimistic update; the snapshot listener reconciles with the server.
        if willBeFavorite {
            favoriteIds.insert(listingId)
        } else {
            favoriteIds.remove(listingId)
        }
        
        let change = willBeFavorite ? FieldValue.arrayUnion([listingId]) : FieldValue.arrayRemove([listingId])
        db.collection("favorites").document(uid).setData(["listingIds": change], merge: true) { [weak self] error in
            guard let error = error else { return }
            print("Error updating favorite status: \(error.localizedDescription)")
            DispatchQueue.main.async {
                if willBeFavorite {
                    self?.favoriteIds.remove(listingId)
                } else {
                    self?.favoriteIds.insert(listingId)
                }
            }
        }
    }
    
    /// Removes all listeners and clears cached data (used on sign-out).
    func stopListening() {
        myListingsListener?.remove()
        myListingsListener = nil
        myListings.removeAll()
        listener?.remove()
        listener = nil
        favoritesListener?.remove()
        favoritesListener = nil
        listings.removeAll()
        filteredListings.removeAll()
        favoriteIds.removeAll()
    }

    @MainActor
    func refreshListings() async {
        guard let userProfile = userProfileService?.userProfile else { return }
        
        // Remove previous listener
        listener?.remove()
        
        // Clear existing listings
        listings.removeAll()
        filteredListings.removeAll()
        
        // Fetch fresh listings
        fetchListings(for: userProfile.role)
    }
}


//func resetTime(dateRange: ClosedRange<Date>) -> ClosedRange<Date> {
//    let calendar = Calendar.current
//    let startComponents = calendar.dateComponents([.year, .month, .day], from: dateRange.lowerBound)
//    let endComponents = calendar.dateComponents([.year, .month, .day], from: dateRange.upperBound)
//
//    let startDate = calendar.date(from: startComponents)!
//    let endDate = calendar.date(from: endComponents)!
//
//    return startDate...endDate
//}
