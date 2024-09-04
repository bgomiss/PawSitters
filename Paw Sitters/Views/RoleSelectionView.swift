//
//  RoleSelectionView.swift
//  Paw Sitters
//
//  Created by aycan duskun on 21.06.2024.
//

import SwiftUI

struct RoleSelectionView: View {
    @Binding var isLoading: Bool // Convert to @Binding
    @Binding var userId: String
    @EnvironmentObject var navigationPathManager: NavigationPathManager
    @EnvironmentObject var userProfileService: UserProfileService
    @ObservedObject var messagingService: MessagingService
    @ObservedObject var storageService: StorageService
    @ObservedObject var firestoreService: FirestoreService
    
    
    var body: some View {
        NavigationStack(path: $navigationPathManager.path) {
            VStack {
                Text("Welcome to Pet Sitter App")
                    .font(.largeTitle)
                    .padding()
                
                Text("Please select your role")
                    .font(.headline)
                    .padding()
                
                Button(action: {
                    userProfileService.userProfile = UserProfile(role: "Sitter")
                    navigationPathManager.push(.sitterSignUp)
                }) {
                    Text("I am a Sitter")
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                
                Button(action: {
                    userProfileService.userProfile = UserProfile(role: "Owner")
                    navigationPathManager.push(.ownerSignUp)
                }) {
                    Text("I am a Pet/House Owner")
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                
                Spacer().frame(height: 20)
                
                Text("I already have an account")
                
                Button(action: {
                    navigationPathManager.push(.signInView)
                }) {
                    Text("Sign In")
                        .padding()
                        .background(Color.orange)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            }
            .navigationDestination(for: NavigationDestination.self) { destination in
                    switch destination {
                    case .sitterSignUp:
                        SignUpView(isLoading: $isLoading, userId: $userId, messagingService: messagingService, firestoreService: firestoreService, role: "Sitter")
                    case .ownerSignUp:
                        SignUpView(isLoading: $isLoading, userId: $userId, messagingService: messagingService, firestoreService: firestoreService, role: "Owner")
                    case .signInView:
                        SignInView(isLoading: $isLoading, userId: $userId, messagingService: messagingService, storageService: storageService, firestoreService: firestoreService)
                    case .contentView:
                        if let role = userProfileService.userProfile?.role {
                            ContentView(isLoading: $isLoading, userId: $userId, firestoreService: firestoreService, messagingService: messagingService, storageService: storageService, role: role)
                        }
                    default:
                        Text("roleSection")
                    }
                }
            }
        }
    }

struct RoleSelectionView_Previews: PreviewProvider {
    static var previews: some View {
        RoleSelectionView(isLoading: .constant(false), userId: .constant("9FFPiZroJ2Nb9zneZer9NDleUpM2"), messagingService: MessagingService(), storageService: StorageService(), firestoreService: FirestoreService())
            .environmentObject(NavigationPathManager())
            .environmentObject(UserProfileService(authService: AuthService()))
    }
}





