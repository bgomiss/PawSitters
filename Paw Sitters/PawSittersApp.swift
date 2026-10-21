//
//  Paw_SittersApp.swift
//  Paw Sitters
//
//  Created by aycan duskun on 21.06.2024.
//

import SwiftUI
import Firebase
import FirebaseStorage

@main
struct PawSittersApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var authService: AuthService
    @StateObject private var userProfileService: UserProfileService
    @StateObject private var firestoreService: FirestoreService
    @StateObject private var storageService = StorageService()
    @StateObject private var messagingService = MessagingService()
    @StateObject private var applicationService = ApplicationService()
    @StateObject private var reviewService = ReviewService()
    @StateObject private var navigationPathManager = NavigationPathManager()
    @State private var isLoading = true // Define the loading state
    @State private var isSignedUp = false
    @State private var userId = ""
    @State private var receiverId = ""
    @State private var showSplash = true

    init() {
        FirebaseApp.configure()
        FirebaseEmulator.configureIfRequested()

        // Services must be created once and shared; creating them inside `body`
        // recreated them (and lost their state) on every scene update.
        let authService = AuthService()
        let userProfileService = UserProfileService(authService: authService)
        let firestoreService = FirestoreService()
        firestoreService.userProfileService = userProfileService
        _authService = StateObject(wrappedValue: authService)
        _userProfileService = StateObject(wrappedValue: userProfileService)
        _firestoreService = StateObject(wrappedValue: firestoreService)
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
                MainAppView(isSignedUp: $isSignedUp, isLoading: $isLoading, userId: userId, receiverId: $receiverId)
                if showSplash {
                    SplashView {
                        withAnimation(.easeInOut(duration: 0.5)) { showSplash = false }
                    }
                    .transition(.opacity.combined(with: .scale(scale: 1.1)))
                    .zIndex(1)
                }
            }
                .tint(AppTheme.current.primary)
                // The themed screens are designed for light mode.
                .preferredColorScheme(.light)
                .environmentObject(authService)
                .environmentObject(firestoreService)
                .environmentObject(storageService)
                .environmentObject(userProfileService)
                .environmentObject(navigationPathManager)
                .environmentObject(messagingService)
                .environmentObject(applicationService)
                .environmentObject(reviewService)
                .onOpenURL { url in
                    // Handle deep links
                    if url.scheme == "pawsitters" {
                        handleDeepLink(url)
                    }
                }
        }
    }

    func handleDeepLink(_ url: URL) {
        // Parse URL and navigate accordingly
    }
}

/// Points Firebase at the local Emulator Suite when the app is launched with
/// `-useFirebaseEmulator YES` (Debug builds only), so you can test without
/// touching the production project. See `firebase.json` in the repo root.
///
/// On a physical device also pass `-emulatorHost <your-mac>.local` so the phone
/// reaches the emulators on your Mac over Wi-Fi. Both settings are remembered,
/// so later launches from the home screen keep using the emulators until the app
/// is launched with `-useFirebaseEmulator NO`.
enum FirebaseEmulator {
    static func configureIfRequested() {
        #if DEBUG
        let defaults = UserDefaults.standard
        let arguments = ProcessInfo.processInfo.arguments
        // Launch arguments only last for one launch; persist them for home-screen launches.
        for key in ["useFirebaseEmulator", "emulatorHost"] where arguments.contains("-\(key)") {
            defaults.set(defaults.object(forKey: key), forKey: key)
        }
        guard defaults.bool(forKey: "useFirebaseEmulator") else { return }
        let host = defaults.string(forKey: "emulatorHost") ?? "127.0.0.1"
        Auth.auth().useEmulator(withHost: host, port: 9099)
        let settings = Firestore.firestore().settings
        settings.host = "\(host):8080"
        settings.cacheSettings = MemoryCacheSettings()
        settings.isSSLEnabled = false
        Firestore.firestore().settings = settings
        Storage.storage().useEmulator(withHost: host, port: 9199)
        print("Using local Firebase emulators at \(host)")
        #endif
    }
    
    /// Debug + emulator only: credentials passed with `-emulatorEmail` / `-emulatorPassword`
    /// to prefill the sign-in and sign-up forms during simulator testing.
    static var prefilledCredentials: (email: String, password: String)? {
        #if DEBUG
        let defaults = UserDefaults.standard
        guard defaults.bool(forKey: "useFirebaseEmulator"),
              let email = defaults.string(forKey: "emulatorEmail"),
              let password = defaults.string(forKey: "emulatorPassword") else { return nil }
        return (email, password)
        #else
        return nil
        #endif
    }
}

