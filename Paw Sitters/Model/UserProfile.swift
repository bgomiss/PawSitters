//
//  UserProfile.swift
//  Paw Sitters
//
//  Created by aycan duskun on 21.06.2024.
//

import FirebaseFirestoreSwift

struct UserProfile: Codable, Identifiable {
   @DocumentID var id: String?
    //var uid: String
    var email: String?
    var name: String?
    var profileImageUrl: String?
    var description: String?
    var role: String
    var age: String?
    var location: String?
    /// Mirrors Firebase Auth's verified-email flag so other users can see the badge.
    /// Firestore rules only accept `true` from a token whose email is verified.
    var emailVerified: Bool?
}

