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
    
    func fetchListings(for role: String, completion: @escaping (Result<[PetSittingListing], Error>) -> Void) {
        guard let userID = Auth.auth().currentUser?.uid else { return }
        let collection = role == "Sitter" ? "ownersListings" : "sittersListings"
        db.collection(collection).getDocuments { (querySnapshot, error) in
            if let error = error {
                completion(.failure(error))
            } else {
                let listings = querySnapshot?.documents.compactMap { document in
                    try? document.data(as: PetSittingListing.self)
                } ?? []
                completion(.success(listings))
            }
        }
    }
    
    func addListing(_ listing: PetSittingListing, completion: @escaping (Result<Void, Error>) -> Void) {
        let collection = listing.role == "Sitter" ? "sittersListings" : "ownersListings"
        do {
            _ = try db.collection(collection).addDocument(from: listing, completion: { error in
                if let error = error {
                    completion(.failure(error))
                } else {
                    completion(.success(()))
                }
            })
        } catch let error {
            completion(.failure(error))
        }
    }
}



