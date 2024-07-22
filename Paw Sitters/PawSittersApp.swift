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
    @StateObject private var authService = AuthService()
    @StateObject private var firestoreService = FirestoreService()
    @StateObject private var storageService = StorageService()
    @StateObject private var messagingService = MessagingService()
    @StateObject private var navigationPathManager = NavigationPathManager()
    @State private var isLoading = true // Define the loading state
    @State private var isSignedUp = false
    @State private var userId = ""
    @State private var receiverId = ""
    
    init() {
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            MainAppView(isSignedUp: $isSignedUp, isLoading: $isLoading, userId: $userId, receiverId: $receiverId, messagingService: messagingService)
                .environmentObject(authService)
                .environmentObject(firestoreService)
                .environmentObject(storageService)
                .environmentObject(UserProfileService(authService: authService))
                .environmentObject(navigationPathManager)
        }
    }
}


