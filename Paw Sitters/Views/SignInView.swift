//
//  SignInView.swift
//  Paw Sitters
//
//  Created by aycan duskun on 21.06.2024.
//

import SwiftUI
import FirebaseAuth

struct SignInView: View {
    @Binding var isLoading: Bool // Add this line to accept isLoading as a binding
    @Binding var userId: String
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var isPresenting = false
    @State private var role: String?
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var userProfileService: UserProfileService
    @ObservedObject var messagingService: MessagingService
    @EnvironmentObject var navigationPathManager: NavigationPathManager

    var body: some View {
   //     NavigationStack(path: $navigationPathManager.path) {
            VStack {
                Text("Sign In")
                    .font(.largeTitle)
                    .padding()
                
                TextField("Email", text: $email)
                    .autocapitalization(.none)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                
                SecureField("Password", text: $password)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                
                Button(action: {
                    isLoading = true
                    authService.signIn(email: email, password: password) { result in
                        switch result {
                        case .success(let user):
                            determineRoleAndFetchUserProfile(user)
                            isLoading = false
                         case .failure(let error):
                            print("Error signing in: \(error.localizedDescription)")
                            isLoading = false
                        }
                    }
                }) {
                    Text("Sign In")
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            }
            .padding()
            .navigationDestination(for: NavigationDestination.self) { destination in
                switch destination {
                case .contentView:
                    if let role = self.role {
                        ContentView(isLoading: $isLoading, userId: $userId, messagingService: messagingService, role: role)
                    }
                default:
                    Text("Guimel2")
                }
            }
        }
 //   }
    private func determineRoleAndFetchUserProfile(_ user: User) {
            userProfileService.fetchUserProfile(uid: user.uid) { result in
                switch result {
                case .success(let profile):
                    DispatchQueue.main.async {
                        self.role = profile.role
                        self.userProfileService.userProfile = profile
                        self.navigationPathManager.push(.contentView)
                        isLoading = false
                    }
                case .failure(let error):
                    print("Error fetching user profile: \(error.localizedDescription)")
                    isLoading = false
                }
            }
        }
    }
//    private func determineRoleAndFetchUserProfile(_ user: User) {
//        // Attempt to fetch from sitters collection first
//        userProfileService.fetchUserProfile(uid: user.uid, from: "sitters") { result in
//            switch result {
//            case .success(let profile):
//                    self.role = profile.role
//                    self.userProfileService.userProfile = profile
//                    navigationPathManager.push(.contentView)
//                
//            case .failure:
//                // If not found in sitters, try owners collection
//                self.userProfileService.fetchUserProfile(uid: user.uid, from: "owners") { result in
//                    switch result {
//                    case .success(let profile):
//                            self.role = profile.role
//                            self.userProfileService.userProfile = profile
//                            navigationPathManager.push(.contentView)
//                        
//                    case .failure(let error):
//                            print("Error fetching user profile: \(error.localizedDescription)")
//                            self.isPresenting = false
//                            isLoading = false
//                    }
//                }
//            }
//        }
//    }
//}

struct SignInView_Previews: PreviewProvider {
    static var previews: some View {
        SignInView(isLoading: .constant(false), userId: .constant("9FFPiZroJ2Nb9zneZer9NDleUpM2"), messagingService: MessagingService())
            .environmentObject(AuthService())
            .environmentObject(UserProfileService(authService: AuthService()))
            .environmentObject(NavigationPathManager())
    }
}


