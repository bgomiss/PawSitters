//
//  SigninViewModel.swift
//  Paw Sitters
//
//  Created by aycan duskun on 12.10.2024.
//

import SwiftUI
import FirebaseAuth

class SigninViewModel: ObservableObject {
    
    private var role: String?
    @Binding var isLoading: Bool
    @Published var showingAlert = false
    @Published var alertTitle = ""
    @Published var alertMessage = ""
    
    var messagingService: MessagingService?
    var storageService: StorageService?
    var authService: AuthService?
    var firestoreService: FirestoreService?
    var userProfileService: UserProfileService?
    var navigationPathManager: NavigationPathManager?
    
    init(isLoading: Binding<Bool>) {
        self._isLoading = isLoading
    }
    
     func determineRoleAndFetchUserProfile(_ user: User) {
         guard let userProfileService = userProfileService, let navigationPathManager = navigationPathManager else { return }
            userProfileService.fetchUserProfile(uid: user.uid) { result in
                switch result {
                case .success(let profile):
                   // DispatchQueue.main.async {
                        self.role = profile.role
                        userProfileService.userProfile = profile
                        navigationPathManager.push(.contentView)
                        self.isLoading = false
                    //}
                case .failure(let error):
                    self.showingAlert = true
                    print("Error fetching user profile: \(error.localizedDescription)")
                    self.isLoading = false
                    self.alertTitle = "Error"
                    self.alertMessage = error.localizedDescription
                    
                }
            }
        }
}

