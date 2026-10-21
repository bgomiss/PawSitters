//
//  SignUpView.swift
//  Paw Sitters
//
//  Created by aycan duskun on 21.06.2024.
//

import SwiftUI
import FirebaseAuth

struct SignUpView: View {
    @Binding var isLoading: Bool // Convert to @Binding
    @Binding var userId: String
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var name: String = ""
    @State private var title: String = ""
    @State private var description: String = ""
    @State private var age: String = ""
    @State private var location: String = ""
    @State private var images: [UIImage] = []
    @State private var showingImagePicker = false
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var userProfileService: UserProfileService
    @EnvironmentObject var storageService: StorageService
    @EnvironmentObject var navigationPathManager: NavigationPathManager
    @ObservedObject var messagingService: MessagingService
    @ObservedObject var firestoreService: FirestoreService
    @State private var showError = false
    @State private var errorMessage: String = ""
    
    var role: String
    
    @State private var isSubmitting = false
    
    @ViewBuilder
    private func loadingOverlay() -> some View {
        // Local state: toggling the shared `isLoading` would swap MainAppView's root
        // for the splash screen and tear down this navigation stack.
        if isSubmitting {
            LoadingView(message: "Creating account...")
                .ignoresSafeArea()
        }
    }
    
    private let theme = AppTheme.current
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                VStack(spacing: 6) {
                    Text("Create your account")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(theme.text)
                    Text(role == "Sitter" ? "Signing up as a sitter" : "Signing up as a pet or home owner")
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundStyle(theme.text.opacity(0.7))
                }
                .padding(.top, 16)
                
                Button {
                    showingImagePicker = true
                } label: {
                    ZStack(alignment: .bottomTrailing) {
                        Group {
                            if let image = images.first {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFill()
                            } else {
                                Image(systemName: role == "Sitter" ? "person.fill" : "dog.fill")
                                    .font(.system(size: 40))
                                    .foregroundStyle(theme.primary)
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                                    .background(theme.secondary.opacity(0.5))
                            }
                        }
                        .frame(width: 96, height: 96)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(.white, lineWidth: 4))
                        .shadow(color: .black.opacity(0.1), radius: 6, y: 3)
                        
                        Image(systemName: "camera.fill")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(8)
                            .background(theme.accent, in: Circle())
                    }
                }
                .accessibilityLabel("Select profile image")
                
                VStack(spacing: 12) {
                    ThemedTextField(icon: "person.fill", placeholder: "Name", text: $name)
                        .textContentType(.name)
                    ThemedTextField(icon: "text.badge.star", placeholder: "Title", text: $title)
                    ThemedTextField(icon: "text.alignleft", placeholder: "About you", text: $description)
                    HStack(spacing: 12) {
                        ThemedTextField(icon: "number", placeholder: "Age", text: $age)
                            .keyboardType(.numberPad)
                        ThemedTextField(icon: "mappin.and.ellipse", placeholder: "Location", text: $location)
                    }
                }
                .padding(16)
                .themedCard()
                
                VStack(spacing: 12) {
                    ThemedTextField(icon: "envelope.fill", placeholder: "Email", text: $email)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .keyboardType(.emailAddress)
                        .textContentType(.emailAddress)
                    ThemedTextField(icon: "lock.fill", placeholder: "Password (min. 6 characters)", text: $password, isSecure: true)
                        .textContentType(.newPassword)
                }
                .padding(16)
                .themedCard()
                
                Button(action: signUp) {
                    Text("Sign Up")
                        .themedButton()
                }
                .disabled(isSubmitting)
                .padding(.bottom, 24)
            }
            .padding(.horizontal, 20)
        }
        .scrollDismissesKeyboard(.interactively)
        .pawBackground()
        .onAppear {
            if email.isEmpty, let credentials = FirebaseEmulator.prefilledCredentials {
                email = credentials.email
                password = credentials.password
            }
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(images: $images, isForMessaging: false)
        }
        .overlay {
            loadingOverlay()
        }
    }
    
    private func signUp() {
        email = email.trimmingCharacters(in: .whitespacesAndNewlines)
        name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !email.isEmpty, !password.isEmpty, !name.isEmpty else {
            showError("Please fill in name, email and password.")
            return
        }
        
        isSubmitting = true
        authService.signUp(email: email, password: password) { result in
            switch result {
            case .success(let user):
                handleSuccessfulSignUp(user)
            case .failure(let error):
                showError((error as? AppError)?.errorDescription ?? error.localizedDescription)
            }
        }
    }
    
    private func showError(_ message: String) {
        isSubmitting = false
        errorMessage = message
        showError = true
    }
    
    private func handleSuccessfulSignUp(_ user: User) {
        userId = user.uid
        if let image = images.first?.resized(to: CGSize(width: 200, height: 200)) {
            storageService.uploadImage(image, path: "profile_images/\(user.uid).jpg") { result in
                switch result {
                case .success(let imageUrl):
                    saveUserProfile(user.uid, imageUrl: imageUrl)
                case .failure(let error):
                    print("Error uploading image: \(error.localizedDescription)")
                    saveUserProfile(user.uid, imageUrl: nil)
                }
            }
        } else {
            saveUserProfile(user.uid, imageUrl: nil)
        }
    }
    
    private func saveUserProfile(_ uid: String, imageUrl: String?) {
        let profile = UserProfile(id: uid, email: email, name: name, profileImageUrl: imageUrl, description: description, role: role, age: age, location: location)
        let collection = role == "Sitter" ? "sitters" : "owners"
        userProfileService.addUserProfile(profile, to: collection, uid: uid) { result in
            switch result {
            case .success():
                // MainAppView switches to ContentView as soon as the profile is loaded.
                userProfileService.fetchUserProfile(uid: uid) { result in
                    DispatchQueue.main.async {
                        isSubmitting = false
                        if case .failure(let error) = result {
                            showError("Account created, but loading the profile failed: \(error.localizedDescription)")
                        }
                    }
                }
            case .failure(let error):
                // Roll back the half-created account so the user can simply try again.
                Auth.auth().currentUser?.delete { _ in }
                showError("Couldn't save your profile: \(error.localizedDescription) Please try again.")
            }
        }
    }
//    private func saveUserProfile(_ uid: String, imageUrl: String?) {
//            let profile = UserProfile(email: email, name: name, profileImageUrl: imageUrl, description: description, role: role, age: age, location: location)
//            let collection = role == "Sitter" ? "sitters" : "owners"
//            userProfileService.addUserProfile(profile, to: collection, uid: uid)
//            
//        
//        }
}

struct SignUpView_Previews: PreviewProvider {
    static var previews: some View {
        SignUpView(isLoading: .constant(false), userId: .constant("9FFPiZroJ2Nb9zneZer9NDleUpM2"), messagingService: MessagingService(), firestoreService: FirestoreService(), role: "Sitter")
            .environmentObject(AuthService())
            .environmentObject(UserProfileService(authService: AuthService()))
            .environmentObject(StorageService())
            .environmentObject(NavigationPathManager())
    }
}
















