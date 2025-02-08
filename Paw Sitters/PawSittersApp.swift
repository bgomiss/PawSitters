//
//  Paw_SittersApp.swift
//  Paw Sitters
//
//  Created by aycan duskun on 21.06.2024.
//

import SwiftUI
import Firebase

@main
struct PawSittersApp: App {
    // MARK: - Properties
    @StateObject private var authService: AuthService
    @StateObject private var userProfileService: UserProfileService
    @StateObject private var firestoreService: FirestoreService
    @StateObject private var storageService: StorageService
    @StateObject private var messagingService: MessagingService
    @StateObject private var navigationPathManager: NavigationPathManager
    
    @State private var isLoading = true
    @State private var isSignedUp = false
    @State private var userId = ""
    @State private var receiverId = ""
    
    // MARK: - Initialization
    init() {
        // Initialize all services
        let auth = AuthService()
        let userProfile = UserProfileService(authService: auth)
        let firestore = FirestoreService()
        
        // Create StateObjects
        self._authService = StateObject(wrappedValue: auth)
        self._userProfileService = StateObject(wrappedValue: userProfile)
        self._firestoreService = StateObject(wrappedValue: firestore)
        self._storageService = StateObject(wrappedValue: StorageService())
        self._messagingService = StateObject(wrappedValue: MessagingService())
        self._navigationPathManager = StateObject(wrappedValue: NavigationPathManager())
        
        // Configure Firebase
        FirebaseApp.configure()
        
        // Set up dependencies
        firestore.userProfileService = userProfile
    }
    
    // MARK: - Body
    var body: some Scene {
        WindowGroup {
            MainAppView(isSignedUp: $isSignedUp, 
                       isLoading: $isLoading, 
                       userId: userId, 
                       receiverId: $receiverId)
                .environmentObject(authService)
                .environmentObject(firestoreService)
                .environmentObject(storageService)
                .environmentObject(userProfileService)
                .environmentObject(navigationPathManager)
                .environmentObject(messagingService)
                .onOpenURL { url in
                    if url.scheme == "pawsitters" {
                        handleDeepLink(url)
                    }
                }
        }
    }
    
    // MARK: - Deep Linking
    func handleDeepLink(_ url: URL) {
        // Parse URL and navigate accordingly
    }
}


