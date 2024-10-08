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
    func fetchListings(for role: String) {
        guard let _ = Auth.auth().currentUser?.uid else { return }
        let collection = role == "Sitter" ? "ownersListings" : "sittersListings"
        
        self.listings.removeAll()
        
        db.collection(collection)
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
                            if !self.listings.contains(where: { $0.documentId == docId }) {
                                let newListing = PetSittingListing(documentId: docId, data: data)
                                    self.listings.append(newListing)
                                }
                        case .removed:
                            self.listings.removeAll { $0.documentId == docId }
                        default:
                            break
                        }
                    })
                }
            }
    }
    
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
