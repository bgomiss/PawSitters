//
//  ProfileView.swift
//  Paw Sitters
//
//  Created by aycan duskun on 21.06.2024.
//

import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var userProfileService: UserProfileService
    @EnvironmentObject var navigationPathManager: NavigationPathManager
    @State private var name: String = ""
    @State private var bio: String = ""
    @State private var age: String = ""
    @State private var location: String = ""
    @State private var images: [UIImage] = []
    @State private var showingImagePicker = false
    @State private var showingEditForm = false
    @State private var verificationMessage: String?
    @State private var isCheckingVerification = false
    var role: String
    
    private let theme = AppTheme.current
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Profile header
                VStack(spacing: 12) {
                    Group {
                        if let imageUrl = userProfileService.userProfile?.profileImageUrl, let url = URL(string: imageUrl) {
                            AsyncImage(url: url) { phase in
                                if case .success(let image) = phase {
                                    image.resizable().scaledToFill()
                                } else {
                                    avatarPlaceholder
                                }
                            }
                        } else {
                            avatarPlaceholder
                        }
                    }
                    .frame(width: 120, height: 120)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.white, lineWidth: 4))
                    .shadow(color: .black.opacity(0.12), radius: 8, y: 4)
                    
                    Text(name)
                        .font(.system(.title, design: .rounded).weight(.bold))
                        .foregroundStyle(theme.text)
                    
                    Label(role == "Sitter" ? "Pet sitter" : "Pet or home owner",
                          systemImage: role == "Sitter" ? "figure.walk.motion" : "house.fill")
                        .font(.system(.subheadline, design: .rounded).weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(role == "Sitter" ? theme.primary : theme.accent, in: Capsule())
                    
                    if userProfileService.userProfile?.emailVerified == true || authService.isEmailVerified {
                        VerifiedBadge()
                    }
                }
                .padding(.top, 24)
                
                if !(userProfileService.userProfile?.emailVerified == true || authService.isEmailVerified) {
                    verifyEmailCard
                        .padding(.horizontal)
                }
                
                // About
                VStack(alignment: .leading, spacing: 12) {
                    profileRow(icon: "text.alignleft", title: "About",
                               value: bio.isEmpty ? "Tell others a little about yourself." : bio,
                               isPlaceholder: bio.isEmpty)
                    Divider()
                    profileRow(icon: "mappin.and.ellipse", title: "Location",
                               value: location.isEmpty ? "Not set" : location,
                               isPlaceholder: location.isEmpty)
                    if !age.isEmpty {
                        Divider()
                        profileRow(icon: "number", title: "Age", value: age, isPlaceholder: false)
                    }
                }
                .padding(18)
                .themedCard()
                .padding(.horizontal)
                
                if let uid = authService.user?.uid {
                    ReviewsSection(userId: uid, title: "Your reviews")
                        .padding(.horizontal)
                }
                
                Button {
                    showingEditForm = true
                } label: {
                    Label("Edit profile", systemImage: "pencil")
                        .themedButton()
                }
                
                Button(role: .destructive) {
                    do {
                        PushNotifications.unregisterCurrentUser()
                        SocialSignIn.signOut()
                        try authService.signOut()
                        navigationPathManager.popToRoot() // Clear the navigation stack
                    } catch let error {
                        print("Error signing out: \(error.localizedDescription)")
                    }
                } label: {
                    Label("Sign out", systemImage: "rectangle.portrait.and.arrow.right")
                        .font(.system(.subheadline, design: .rounded).weight(.semibold))
                        .foregroundStyle(.red)
                }
                .padding(.bottom, 24)
            }
            .onAppear {
                if let user = authService.user {
                    userProfileService.fetchUserProfile(uid: user.uid) { result in
                        switch result {
                        case .success(let profile):
                            self.name = profile.name ?? ""
                            self.bio = profile.description ?? ""
                            self.age = profile.age ?? ""
                            self.location = profile.location ?? ""
                            self.userProfileService.userProfile = profile
                        case .failure(let error):
                            print("Error fetching profile: \(error.localizedDescription)")
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(images: $images, isForMessaging: false)
        }
        .sheet(isPresented: $showingEditForm) {
            EditProfileForm(name: $name, bio: $bio, age: $age, location: $location, role: role)
                .environmentObject(userProfileService)
        }
    }
}

extension ProfileView {
    /// Prompts the user to verify their email, which earns the "Verified" badge.
    private var verifyEmailCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Verify your email", systemImage: "envelope.badge.shield.half.filled")
                .font(.system(.headline, design: .rounded))
                .foregroundStyle(theme.text)
            Text("Verified members get a badge that helps others trust them. We sent a link to \(authService.user?.email ?? "your email").")
                .font(.system(.subheadline, design: .rounded))
                .foregroundStyle(theme.text.opacity(0.7))
            if let verificationMessage {
                Text(verificationMessage)
                    .font(.footnote)
                    .foregroundStyle(theme.accent)
            }
            HStack(spacing: 10) {
                Button {
                    authService.sendEmailVerification { error in
                        verificationMessage = error.map { "Couldn't send the link: \($0.localizedDescription)" }
                            ?? "Link sent. Check your inbox (and spam folder)."
                    }
                } label: {
                    Text("Resend link")
                        .font(.system(.subheadline, design: .rounded).weight(.semibold))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .foregroundStyle(theme.primary)
                        .background(theme.primary.opacity(0.12), in: Capsule())
                }
                Button {
                    isCheckingVerification = true
                    authService.reloadUser { verified in
                        isCheckingVerification = false
                        if verified {
                            userProfileService.syncEmailVerified(true)
                            verificationMessage = nil
                        } else {
                            verificationMessage = "Not verified yet. Tap the link in the email first."
                        }
                    }
                } label: {
                    Group {
                        if isCheckingVerification {
                            ProgressView().tint(.white)
                        } else {
                            Text("I've verified")
                        }
                    }
                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .foregroundStyle(.white)
                    .background(theme.primary, in: Capsule())
                }
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .themedCard()
    }
    
    private var avatarPlaceholder: some View {
        Image(systemName: role == "Sitter" ? "person.fill" : "dog.fill")
            .font(.system(size: 48))
            .foregroundStyle(theme.primary)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(theme.secondary.opacity(0.5))
    }
    
    private func profileRow(icon: String, title: String, value: String, isPlaceholder: Bool) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(theme.primary)
                .frame(width: 22)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(.caption, design: .rounded).weight(.semibold))
                    .foregroundStyle(theme.text.opacity(0.55))
                Text(value)
                    .font(.system(.body, design: .rounded))
                    .foregroundStyle(isPlaceholder ? theme.text.opacity(0.45) : theme.text)
            }
            Spacer(minLength: 0)
        }
    }
}

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView(role: "Sitter")
            .environmentObject(AuthService())
            .environmentObject(UserProfileService(authService: AuthService()))
    }
}






