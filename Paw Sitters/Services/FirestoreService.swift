//
//  FirestoreService.swift
//  Paw Sitters
//
//  Created by aycan duskun on 21.06.2024.
//

import FirebaseFirestore
import FirebaseFirestoreSwift
import Firebase

class FirestoreService: ObservableObject {
    private var db = Firestore.firestore()
    @Published var listings: [PetSittingListing] = []
    @Published var filteredListings: [PetSittingListing] = []
    var listener: ListenerRegistration?
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
    func fetchListings(for role: String, location: String? = nil, dateRange: ClosedRange<Date>? = nil, environment: String? = nil) {
            guard let _ = Auth.auth().currentUser?.uid else { return }
            let collection = role == "Sitter" ? "ownersListings" : "sittersListings"
            
            self.listings.removeAll()
            
            var query: Query = db.collection(collection)
            
            // Add filters dynamically based on non-nil and non-empty parameters
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
            
            // Remove previous listener to prevent multiple listeners
            listener?.remove()
            
            // Attach snapshot listener
            listener = query.addSnapshotListener { querySnapshot, error in
                if let error = error {
                    print("FAILED TO LISTEN FOR LISTINGS: \(error.localizedDescription)")
                    return
                }
                
                DispatchQueue.main.async {
                    querySnapshot?.documentChanges.forEach { change in
                        let docId = change.document.documentID
                        let data = change.document.data()
                        
                        switch change.type {
                        case .added:
                            if !self.listings.contains(where: { $0.documentId == docId }) {
                                let newListing = PetSittingListing(documentId: docId, data: data)
                                self.listings.append(newListing)
                            }
                        case .removed:
                            self.listings.removeAll { $0.documentId == docId }
                        default:
                            break
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
    
    func updateFavoriteStatus(role: String, for listingId: String, isFavorite: Bool) {
        let collection = role == "Sitter" ? "ownersListings" : "sittersListings"
        let documentRef = db.collection(collection).document(listingId)
            
        documentRef.updateData(["isFavorite": isFavorite]) { error in
            if let error = error {
                print("Error updating favorite status: \(error.localizedDescription)")
            } else {
                print("Favorite status updated successfully.")
            }
        }
    }

    func refreshListings() async {
        guard let userProfile = userProfileService?.userProfile else { return }
        
        // Remove previous listener
        listener?.remove()
        
        // Clear existing listings
        DispatchQueue.main.async {
            self.listings.removeAll()
            self.filteredListings.removeAll()
        }
        
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
