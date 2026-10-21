//
//  MainAppView.swift
//  Paw Sitters
//
//  Created by aycan duskun on 21.06.2024.
//

//import SwiftUI
//import FirebaseAuth
//
//struct MainAppView: View {
//    @Binding var isSignedUp: Bool
//    @Binding var isLoading: Bool // Convert to @Binding
//    @State var userId: String
//    @Binding var receiverId: String
//    @State var role: String?
//    @State private var animate = false
//    @EnvironmentObject var authService: AuthService
//    @EnvironmentObject var userProfileService: UserProfileService
//    @EnvironmentObject var storageService: StorageService
//    @EnvironmentObject var messagingService: MessagingService
//    @EnvironmentObject var firestoreService: FirestoreService
//    @EnvironmentObject var navigationPathManager: NavigationPathManager
//
//    var body: some View {
//        //     NavigationStack(path: $navigationPathManager.path) {
//        VStack {
//            if isLoading {
//                ZStack {
//                    Image(uiImage: UIImage(named: "background")!)
//                        .resizable()
//                        .edgesIgnoringSafeArea(.all)
//                    HStack {
//                        Image(systemName: "pawprint.fill")
//                            .resizable()
//                            .frame(width: 100, height: 100)
//                            .padding(.trailing, 18)
//                        Image(systemName: "pawprint.fill")
//                            .resizable()
//                            .frame(width: 100, height: 100)
//                    }
//                    .opacity(animate ? 0.2 : 1.0)
//                    .animation(Animation.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: animate)
//                    .onAppear {
//                        self.animate = true
//                    }
//                }
//            } else if isSignedUp {
//                if let role = self.role {
//                    ContentView(isLoading: $isLoading, userId: userId, role: role)
//                        .navigationBarBackButtonHidden(true)
//                }
//            } else if self.role != nil {
//                     RoleSelectionView(isLoading: $isLoading, userId: $userId)
//                }
//            }
//        
//        .navigationDestination(for: NavigationDestination.self) { destination in
//            switch destination {
//            case .sitterSignUp:
//                SignUpView(isLoading: $isLoading, userId: $userId, messagingService: messagingService, firestoreService: firestoreService, role: "Sitter")
//            case .ownerSignUp:
//                SignUpView(isLoading: $isLoading, userId: $userId, messagingService: messagingService, firestoreService: firestoreService, role: "Owner")
//            case .signInView:
//                SignInView(isLoading: $isLoading, userId: $userId, role: role ?? "")
//            case .contentView:
//               ContentView(isLoading: $isLoading, userId: userId, role: role)
//                
//            default:
//                Text("roleSection")
//            }
//        }
//    
//   //     }
//        
//        .onAppear {
//            isLoading = true
//            if let user = authService.user {
//                fetchUserProfile(for: user)
//            } else {
//                isLoading = false
//                isSignedUp = false
//            }
//        }
//       
//        .onReceive(authService.$user) { user in
//            if let user = user {
//                userId = user.uid
//                fetchUserProfile(for: user)
//            } else {
//                isSignedUp = false
//                isLoading = false
//            }
//        }
//        
//    }
//    
//    private func fetchUserProfile(for user: User) {
//       // DispatchQueue.main.async {
//            userProfileService.fetchUserProfile(uid: user.uid) { result in
//                switch result {
//                case .success(let profile):
//                    DispatchQueue.main.async {
//                        userProfileService.userProfile = profile
//                        self.role = profile.role
//                        isSignedUp = true
//                    }
//                case .failure(let error):
//                    print("Error fetching user profile: \(error.localizedDescription)")
//                    isSignedUp = false
//                }
//                isLoading = false
//            }
//         }
//      }
//  // }
//
//
//struct MainAppView_Previews: PreviewProvider {
//    static var previews: some View {
//        MainAppView(isSignedUp: .constant(false), isLoading: .constant(false), userId: "9FFPiZroJ2Nb9zneZer9NDleUpM2", receiverId: .constant("HZHDnLPFWfftcb3e0Mjz4DIoYZn2"))
//            .environmentObject(AuthService())
//            .environmentObject(UserProfileService(authService: AuthService()))
//            .environmentObject(StorageService())
//            .environmentObject(NavigationPathManager())
//    }
//}
//
//
//  MainAppView.swift
//  Paw Sitters
//
//  Created by aycan duskun on 21.06.2024.
//

import SwiftUI
import FirebaseAuth

struct MainAppView: View {
    @Binding var isSignedUp: Bool
    @Binding var isLoading: Bool
    @State var userId: String
    @Binding var receiverId: String
    @State private var animate = false
    
    // Environment Objects
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var userProfileService: UserProfileService
    @EnvironmentObject var storageService: StorageService
    @EnvironmentObject var messagingService: MessagingService
    @EnvironmentObject var firestoreService: FirestoreService
    @EnvironmentObject var navigationPathManager: NavigationPathManager
    @EnvironmentObject var applicationService: ApplicationService
    @EnvironmentObject var reviewService: ReviewService
    
    /// The signed-in user's role, available only once their profile has been loaded.
    private var signedInRole: String? {
        guard let uid = authService.user?.uid,
              let profile = userProfileService.userProfile,
              profile.id == uid else { return nil }
        return profile.role
    }
    
    var body: some View {
        Group {
            if isLoading {
                loadingScreen
            } else if let role = signedInRole {
                // ContentView owns its own NavigationStack, so it must not be nested in another one.
                ContentView(isLoading: $isLoading, userId: userId, role: role)
                    .id(userId)
            } else {
                NavigationStack(path: $navigationPathManager.path) {
                    RoleSelectionView(isLoading: $isLoading, userId: $userId)
                        .navigationDestination(for: NavigationDestination.self) { destination in
                            switch destination {
                            case .sitterSignUp:
                                SignUpView(
                                    isLoading: $isLoading,
                                    userId: $userId,
                                    messagingService: messagingService,
                                    firestoreService: firestoreService,
                                    role: "Sitter"
                                )
                            case .ownerSignUp:
                                SignUpView(
                                    isLoading: $isLoading,
                                    userId: $userId,
                                    messagingService: messagingService,
                                    firestoreService: firestoreService,
                                    role: "Owner"
                                )
                            case .signInView:
                                SignInView(isLoading: $isLoading, userId: $userId, role: "")
                            default:
                                EmptyView()
                            }
                        }
                }
            }
        }
        .onAppear {
            checkInitialAuthState()
        }
        .onReceive(authService.$user.removeDuplicates { $0?.uid == $1?.uid }) { user in
            handleAuthStateChange(user: user)
        }
        .onChange(of: signedInRole) { _, role in
            isSignedUp = role != nil
            // Leave the sign-in / sign-up screens behind once the user is in (or out).
            navigationPathManager.popToRoot()
        }
    }
    
    private var loadingScreen: some View {
        ZStack {
            PawPatternBackground()
            VStack(spacing: 16) {
                HStack(spacing: 18) {
                    ForEach(0..<3) { index in
                        Image(systemName: "pawprint.fill")
                            .font(.system(size: 34))
                            .foregroundStyle(AppTheme.current.primary)
                            .opacity(animate ? 1 : 0.2)
                            .animation(
                                .easeInOut(duration: 0.6).repeatForever(autoreverses: true).delay(Double(index) * 0.2),
                                value: animate
                            )
                    }
                }
                Text("Loading…")
                    .font(.system(.headline, design: .rounded))
                    .foregroundStyle(AppTheme.current.text)
            }
            .onAppear { animate = true }
        }
    }
    
    // MARK: - Helper Methods
    private func checkInitialAuthState() {
        if let user = authService.user {
            userId = user.uid
            fetchUserProfile(for: user)
        } else {
            isLoading = false
            isSignedUp = false
        }
    }
    
    private func handleAuthStateChange(user: User?) {
        if let user = user {
            userId = user.uid
            // Skip the fetch if this profile is already loaded (e.g. right after sign-up/sign-in).
            if userProfileService.userProfile?.id == user.uid {
                isLoading = false
            } else {
                fetchUserProfile(for: user)
            }
        } else {
            userId = ""
            userProfileService.userProfile = nil
            firestoreService.stopListening()
            messagingService.clearMessages()
            applicationService.stopListening()
            reviewService.stopListening()
            isSignedUp = false
            isLoading = false
        }
    }
    
    private func fetchUserProfile(for user: User) {
        userProfileService.fetchUserProfile(uid: user.uid) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let profile):
                    userProfileService.userProfile = profile
                case .failure(let error):
                    // Expected right after sign-up: the profile document is written a moment later.
                    print("Profile fetch failed: \(error.localizedDescription)")
                }
                isLoading = false // Always stop loading
            }
        }
    }
}

// MARK: - Preview
struct MainAppView_Previews: PreviewProvider {
    static var previews: some View {
        MainAppView(
            isSignedUp: .constant(false),
            isLoading: .constant(false),
            userId: "TEST_USER_ID",
            receiverId: .constant("TEST_RECEIVER_ID")
        )
        .environmentObject(AuthService())
        .environmentObject(UserProfileService(authService: AuthService()))
        .environmentObject(StorageService())
        .environmentObject(NavigationPathManager())
    }
}
