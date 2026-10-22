//
//  AuthService.swift
//  Paw Sitters
//
//  Created by aycan duskun on 21.06.2024.
//

import FirebaseAuth

class AuthService: ObservableObject {
    @Published var user: User?
    
    init() {
        Auth.auth().addStateDidChangeListener { [weak self] _, user in
            self?.user = user
        }
    }
    
    func signUp(email: String, password: String, completion: @escaping (Result<User, Error>) -> Void) {
        Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
            if let error = error {
                completion(.failure(error))
            } else if let user = authResult?.user {
                completion(.success(user))
            }
        }
    }
    
    func signIn(email: String, password: String, completion: @escaping (Result<User, Error>) -> Void) {
        Auth.auth().signIn(withEmail: email, password: password) { authResult, error in
            if let error = error {
                completion(.failure(error))
            } else if let user = authResult?.user {
                completion(.success(user))
            }
        }
    }
    
    func sendEmailVerification(completion: @escaping (Error?) -> Void) {
        guard let user = Auth.auth().currentUser else { return }
        user.sendEmailVerification { error in
            DispatchQueue.main.async { completion(error) }
        }
    }
    
    /// Reloads the user from Firebase and refreshes the ID token, so a freshly
    /// verified email is reflected both in the app and in Firestore rules.
    func reloadUser(completion: @escaping (Bool) -> Void) {
        guard let user = Auth.auth().currentUser else { return completion(false) }
        user.reload { _ in
            let current = Auth.auth().currentUser
            current?.getIDTokenForcingRefresh(true) { _, _ in
                DispatchQueue.main.async { completion(current?.isEmailVerified ?? false) }
            }
        }
    }
    
    var isEmailVerified: Bool {
        Auth.auth().currentUser?.isEmailVerified ?? false
    }
    
    /// Permanently deletes the account and everything that belongs to it
    /// (done server-side by the `deleteAccount` Cloud Function), then signs out.
    func deleteAccount() async throws {
        guard let user = Auth.auth().currentUser else { return }
        let idToken = try await user.getIDToken()
        var request = URLRequest(url: FirebaseEmulator.functionURL(named: "deleteAccount"))
        request.httpMethod = "POST"
        request.setValue("Bearer \(idToken)", forHTTPHeaderField: "Authorization")
        let (_, response) = try await URLSession.shared.data(for: request)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            throw AppError.networkError("Couldn't delete your account. Check your connection and try again.")
        }
        try? Auth.auth().signOut()
    }
    
    func signOut() throws {
           try Auth.auth().signOut()
           //self.user = nil
       }
}

