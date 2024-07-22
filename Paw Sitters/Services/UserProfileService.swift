//
//  UserProfileService.swift
//  Paw Sitters
//
//  Created by aycan duskun on 21.06.2024.
//

import FirebaseFirestore
import SwiftUI

class UserProfileService: ObservableObject {
    private var db = Firestore.firestore()
    @Published var userProfile: UserProfile?
    @Published var users: [UserProfile] = []
    @Published var authService: AuthService?
        
    init(authService: AuthService?) {
        if authService != nil {
            self.authService = authService
            fetchAllUsers()
        }
    }
    
    
    func fetchAllUsers() {
        guard let currentUserId = authService?.user?.uid else { return }
            
            var allUsers: [UserProfile] = []
            
            // Fetch sitters
            db.collection("sitters").getDocuments { snapshot, error in
                if let snapshot = snapshot {
                    let sitters = snapshot.documents.compactMap { try? $0.data(as: UserProfile.self) }
                    let filteredSitters = sitters.filter { $0.id != currentUserId }
                    allUsers.append(contentsOf: filteredSitters)
                }
                
                // Fetch owners
                self.db.collection("owners").getDocuments { snapshot, error in
                    if let snapshot = snapshot {
                        let owners = snapshot.documents.compactMap { try? $0.data(as: UserProfile.self) }
                        let filteredOwners = owners.filter { $0.id != currentUserId }
                        allUsers.append(contentsOf: filteredOwners)
                    }
                    
                    // Update published users array on main thread
                    DispatchQueue.main.async {
                        self.users = allUsers
                    }
                }
            }
        }
    
    func fetchUserProfile(uid: String, completion: @escaping (Result<UserProfile, Error>) -> Void) {
            fetchUserProfile(uid: uid, from: "sitters") { result in
                switch result {
                case .success(let profile):
                    self.userProfile = profile
                    completion(.success(profile))
                case .failure:
                    self.fetchUserProfile(uid: uid, from: "owners") { result in
                        switch result {
                        case .success(let profile):
                            self.userProfile = profile
                            completion(.success(profile))
                        case .failure(let error):
                            completion(.failure(error))
                        }
                    }
                }
            }
     //   fetchAllUsers()
        }
    
    private func fetchUserProfile(uid: String, from collection: String, completion: @escaping (Result<UserProfile, Error>) -> Void) {
        let docRef = db.collection(collection).document(uid)
        docRef.getDocument { document, error in
            if let document = document, document.exists {
                do {
                    var userProfile = try document.data(as: UserProfile.self)
                    userProfile.id = document.documentID  // Ensure ID is set
                    self.userProfile = userProfile
                    completion(.success(userProfile))
                } catch {
                    completion(.failure(error))
                }
            } else {
                completion(.failure(error ?? NSError(domain: "User not found", code: -1, userInfo: nil)))
            }
        }
    }
    
    func fetchUserProfiles(from collection: String, completion: @escaping (Result<[UserProfile], Error>) -> Void) {
            db.collection(collection).getDocuments { snapshot, error in
                if let error = error {
                    completion(.failure(error))
                } else if let snapshot = snapshot {
                    let profiles = snapshot.documents.compactMap { document -> UserProfile? in
                        var userProfile = try? document.data(as: UserProfile.self)
                        userProfile?.id = document.documentID  // Ensure ID is set
                        return userProfile
                    }
                    completion(.success(profiles))
                }
            }
        }
    
    func updateUserProfile(_ profile: UserProfile, in collection: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let uid = profile.id else {
            completion(.failure(NSError(domain: "Invalid profile id", code: -1, userInfo: nil)))
            return
        }
        
        
        do {
            try db.collection(collection).document(uid).setData(from: profile) { error in
                if let error = error {
                    completion(.failure(error))
                } else {
                    completion(.success(()))
                }
            }
        } catch let error {
            completion(.failure(error))
        }
    }
    
    func addUserProfile(_ profile: UserProfile, to collection: String, uid: String, completion: @escaping (Result<Void, Error>) -> Void) {
        do {
            try db.collection(collection).document(uid).setData(from: profile) { error in
                if let error = error {
                    completion(.failure(error))
                } else {
                    completion(.success(()))
                }
            }
        } catch let error {
            completion(.failure(error))
        }
    }
}



