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
    @EnvironmentObject var messagingService: MessagingService
    @EnvironmentObject var storageService: StorageService
    @EnvironmentObject var firestoreService: FirestoreService
    
    
    private let theme = AppTheme.current
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(theme.primary)
                        .frame(width: 110, height: 110)
                    Image(systemName: "pawprint.fill")
                        .font(.system(size: 52))
                        .foregroundStyle(.white)
                }
                .shadow(color: theme.primary.opacity(0.35), radius: 10, y: 5)
                
                Text("Welcome to Paw Sitters")
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundStyle(theme.text)
                    .multilineTextAlignment(.center)
                Text("Find a trusted sitter, or a home full of furry friends.")
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(theme.text.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            
            Spacer()
            
            VStack(spacing: 14) {
                Text("How will you use Paw Sitters?")
                    .font(.system(.headline, design: .rounded))
                    .foregroundStyle(theme.text)
                
                roleCard(title: "I'm a sitter",
                         subtitle: "Look after pets and homes",
                         icon: "figure.walk.motion",
                         color: theme.primary) {
                    userProfileService.userProfile = UserProfile(role: "Sitter")
                    navigationPathManager.push(.sitterSignUp)
                }
                
                roleCard(title: "I'm a pet or home owner",
                         subtitle: "Find someone you can trust",
                         icon: "house.fill",
                         color: theme.accent) {
                    userProfileService.userProfile = UserProfile(role: "Owner")
                    navigationPathManager.push(.ownerSignUp)
                }
            }
            .padding(.horizontal, 24)
            
            HStack(spacing: 4) {
                Text("Already have an account?")
                    .foregroundStyle(theme.text.opacity(0.7))
                Button("Sign in") {
                    navigationPathManager.push(.signInView)
                }
                .fontWeight(.semibold)
                .foregroundStyle(theme.primary)
            }
            .font(.system(.subheadline, design: .rounded))
            .padding(.bottom, 24)
        }
        .frame(maxWidth: .infinity)
        .pawBackground()
        // Navigation destinations are registered by MainAppView, which owns the NavigationStack.
    }
    
    private func roleCard(title: String, subtitle: String, icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 48, height: 48)
                    .background(color, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(.headline, design: .rounded))
                        .foregroundStyle(theme.text)
                    Text(subtitle)
                        .font(.system(.footnote, design: .rounded))
                        .foregroundStyle(theme.text.opacity(0.65))
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(theme.text.opacity(0.4))
            }
            .padding(14)
            .themedCard()
        }
        .buttonStyle(.plain)
    }
}

//struct RoleSelectionView_Previews: PreviewProvider {
//    static var previews: some View {
//        RoleSelectionView(isLoading: .constant(false), userId: .constant("9FFPiZroJ2Nb9zneZer9NDleUpM2"), messagingService: MessagingService(), storageService: StorageService(), firestoreService: FirestoreService())
//            .environmentObject(NavigationPathManager())
//            .environmentObject(UserProfileService(authService: AuthService()))
//    }
//}





