//
//  SocialSignInSection.swift
//  Paw Sitters
//
//  "Continue with Apple / Google" buttons for the sign-in and sign-up screens.
//  New users get a profile from the name and email the provider shares; when
//  the role isn't known yet (sign-in screen) they pick it first.
//

import SwiftUI
import FirebaseAuth

struct SocialSignInSection: View {
    /// Role chosen on the welcome screen, or nil on the sign-in screen.
    let role: String?
    @EnvironmentObject var userProfileService: UserProfileService
    @EnvironmentObject var authService: AuthService
    @State private var isWorking = false
    @State private var errorMessage: String?
    @State private var pendingResult: SocialSignInResult?
    @State private var showRolePicker = false
    private let theme = AppTheme.current

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 10) {
                Rectangle().fill(theme.text.opacity(0.15)).frame(height: 1)
                Text("or")
                    .font(.system(.footnote, design: .rounded))
                    .foregroundStyle(theme.text.opacity(0.5))
                Rectangle().fill(theme.text.opacity(0.15)).frame(height: 1)
            }

            Button {
                run { try await SocialSignIn.signInWithApple() }
            } label: {
                providerLabel(title: "Continue with Apple") {
                    Image(systemName: "apple.logo")
                        .font(.system(size: 18, weight: .semibold))
                }
                .foregroundStyle(.white)
                .background(Color.black, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            }

            Button {
                run { try await SocialSignIn.signInWithGoogle() }
            } label: {
                providerLabel(title: "Continue with Google") {
                    GoogleMark()
                }
                .foregroundStyle(Color.black.opacity(0.8))
                .background(Color.white, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.black.opacity(0.12), lineWidth: 1)
                )
            }

            if let errorMessage {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
            }
            
            TermsNotice()
                .padding(.top, 4)
        }
        .buttonStyle(.plain)
        .disabled(isWorking)
        .overlay {
            if isWorking {
                ProgressView().tint(theme.primary)
            }
        }
        .confirmationDialog("How will you use Paw Sitters?", isPresented: $showRolePicker, titleVisibility: .visible) {
            Button("I'm a sitter") { createProfile(role: "Sitter") }
            Button("I'm a pet or home owner") { createProfile(role: "Owner") }
            Button("Cancel", role: .cancel) {
                // No profile was created; don't leave a half-signed-in account behind.
                pendingResult = nil
                SocialSignIn.signOut()
                try? authService.signOut()
            }
        } message: {
            Text("Choose your role to finish creating your account.")
        }
    }

    private func providerLabel<Icon: View>(title: String, @ViewBuilder icon: () -> Icon) -> some View {
        HStack(spacing: 10) {
            icon()
            Text(title)
                .font(.system(.headline, design: .rounded))
        }
        .frame(maxWidth: 320)
        .frame(height: 50)
    }

    private func run(_ signIn: @escaping () async throws -> SocialSignInResult) {
        errorMessage = nil
        isWorking = true
        Task {
            do {
                let result = try await signIn()
                handle(result)
            } catch {
                isWorking = false
                if !SocialSignIn.isCancellation(error) {
                    errorMessage = (error as? AppError)?.errorDescription ?? error.localizedDescription
                }
            }
        }
    }

    /// Existing users go straight in; new users get a profile (after picking a role if needed).
    private func handle(_ result: SocialSignInResult) {
        userProfileService.loadProfile(uid: result.user.uid) { loaded in
            DispatchQueue.main.async {
                if case .success(let profile) = loaded {
                    isWorking = false
                    userProfileService.userProfile = profile
                    userProfileService.syncEmailVerified(result.user.isEmailVerified)
                } else if let role {
                    pendingResult = result
                    createProfile(role: role)
                } else {
                    isWorking = false
                    pendingResult = result
                    showRolePicker = true
                }
            }
        }
    }

    private func createProfile(role: String) {
        guard let result = pendingResult else { return }
        isWorking = true
        let user = result.user
        let profile = UserProfile(id: user.uid,
                                  email: result.email ?? user.email,
                                  name: result.name ?? user.displayName ?? "",
                                  profileImageUrl: user.photoURL?.absoluteString,
                                  description: "",
                                  role: role,
                                  age: "",
                                  location: "",
                                  emailVerified: user.isEmailVerified ? true : nil)
        let collection = role == "Sitter" ? "sitters" : "owners"
        userProfileService.addUserProfile(profile, to: collection, uid: user.uid) { saved in
            if case .failure(let error) = saved {
                DispatchQueue.main.async {
                    isWorking = false
                    errorMessage = "Couldn't create your profile: \(error.localizedDescription)"
                }
                return
            }
            // MainAppView switches to the main screen once the profile is loaded.
            userProfileService.fetchUserProfile(uid: user.uid) { _ in
                DispatchQueue.main.async {
                    isWorking = false
                    pendingResult = nil
                }
            }
        }
    }
}

/// Simple four-colour "G" so the Google button is recognisable without bundling Google's artwork.
private struct GoogleMark: View {
    var body: some View {
        Text("G")
            .font(.system(size: 20, weight: .bold, design: .rounded))
            .foregroundStyle(
                AngularGradient(colors: [Color(hex: 0x4285F4), Color(hex: 0x34A853), Color(hex: 0xFBBC05),
                                         Color(hex: 0xEA4335), Color(hex: 0x4285F4)],
                                center: .center)
            )
    }
}

/// Public web pages (Firebase Hosting) linked from the app and App Store Connect.
enum AppLinks {
    static let terms = URL(string: "https://pawsittersapp.web.app/terms")!
    static let privacy = URL(string: "https://pawsittersapp.web.app/privacy")!
    static let support = URL(string: "https://pawsittersapp.web.app")!
}

/// Shown wherever an account can be created: signing up means accepting the terms.
struct TermsNotice: View {
    var body: some View {
        Text("By continuing you agree to our [Terms of Use](\(AppLinks.terms.absoluteString)), including zero tolerance for objectionable content and abusive users, and our [Privacy Policy](\(AppLinks.privacy.absoluteString)).")
            .font(.system(.caption, design: .rounded))
            .foregroundStyle(AppTheme.current.text.opacity(0.6))
            .tint(AppTheme.current.primary)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 8)
    }
}
