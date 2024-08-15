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
    @Binding var isLoading: Bool // Convert to @Binding
    @Binding var userId: String
    @Binding var receiverId: String
    @State var role: String?
    @State private var animate = false
    
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var userProfileService: UserProfileService
    @EnvironmentObject var storageService: StorageService
    @ObservedObject var messagingService: MessagingService
    @ObservedObject var firestoreService: FirestoreService
    @EnvironmentObject var navigationPathManager: NavigationPathManager

    var body: some View {
        //     NavigationStack(path: $navigationPathManager.path) {
        VStack {
            if isLoading {
                HStack {
                    Image(systemName: "pawprint.fill")
                        .resizable()
                        .frame(width: 100, height: 100)
                        .padding(.trailing, 18)
                    Image(systemName: "pawprint.fill")
                        .resizable()
                        .frame(width: 100, height: 100)
                }
                .opacity(animate ? 0.2 : 1.0)
                .animation(Animation.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: animate)
                .onAppear {
                    self.animate = true
                }
            } else if isSignedUp {
                ContentView(isLoading: $isLoading, userId: $userId, firestoreService: firestoreService, messagingService: messagingService, role: self.role)
                    .navigationBarBackButtonHidden(true)
            } else {
                RoleSelectionView(isLoading: $isLoading, userId: $userId, messagingService: messagingService, firestoreService: firestoreService)
                
            }
            
        }
        .navigationDestination(for: NavigationDestination.self) { destination in
            switch destination {
            case .sitterSignUp:
                SignUpView(isLoading: $isLoading, userId: $userId, messagingService: messagingService, firestoreService: firestoreService, role: "Sitter")
            case .ownerSignUp:
                SignUpView(isLoading: $isLoading, userId: $userId, messagingService: messagingService, firestoreService: firestoreService, role: "Owner")
            case .signInView:
                SignInView(isLoading: $isLoading, userId: $userId, messagingService: messagingService, firestoreService: firestoreService)
            case .contentView:
                if let role = self.role {
                    ContentView(isLoading: $isLoading, userId: $userId, firestoreService: firestoreService, messagingService: messagingService, role: role)
                }
            default:
                Text("roleSection")
            }
        }
    
   //     }
        
        .onAppear {
            if let user = authService.user {
                fetchUserProfile(for: user)
//                isSignedUp = true
//                isLoading = false
            } else {
                isLoading = false
                isSignedUp = false
            }
        }
       
        .onReceive(authService.$user) { user in
            if let user = user {
                userId = user.uid
                fetchUserProfile(for: user)
//                isLoading = true
//                isSignedUp = true
            } else {
                isSignedUp = false
                isLoading = false
            }
        }
        
    }
    private func fetchUserProfile(for user: User) {
            isLoading = true
        DispatchQueue.global().asyncAfter(deadline: .now() + 5) {
            userProfileService.fetchUserProfile(uid: user.uid) { result in
                switch result {
                case .success(let profile):
                    DispatchQueue.main.async {
                        userProfileService.userProfile = profile
                        self.role = profile.role
                        isSignedUp = true
                    }
                case .failure(let error):
                    print("Error fetching user profile: \(error.localizedDescription)")
                    isSignedUp = false
                }
                isLoading = false
//                userProfileService.fetchAllUsers()
            }
         }
      }
   }


struct MainAppView_Previews: PreviewProvider {
    static var previews: some View {
        MainAppView(isSignedUp: .constant(false), isLoading: .constant(false), userId: .constant("9FFPiZroJ2Nb9zneZer9NDleUpM2"), receiverId: .constant("HZHDnLPFWfftcb3e0Mjz4DIoYZn2"), messagingService: MessagingService(), firestoreService: FirestoreService())
            .environmentObject(AuthService())
            .environmentObject(UserProfileService(authService: AuthService()))
            .environmentObject(StorageService())
            .environmentObject(NavigationPathManager())
    }
}






