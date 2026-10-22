//
//  SignInView.swift
//  Paw Sitters
//
//  Created by aycan duskun on 21.06.2024.
//
import SwiftUI
import FirebaseAuth

struct SignInView: View {
    @Binding var isLoading: Bool
    @Binding var userId: String
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var isSubmitting = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var role: String?
    @State private var isResetSheetPresented = false
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var userProfileService: UserProfileService
    
    init(isLoading: Binding<Bool>, userId: Binding<String>, role: String) {
        self.role = role
        self._isLoading = isLoading
        self._userId = userId
    }
    
    private let theme = AppTheme.current
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                VStack(spacing: 8) {
                    Image(systemName: "pawprint.circle.fill")
                        .font(.system(size: 64))
                        .foregroundStyle(theme.primary)
                    Text("Welcome back")
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                        .foregroundStyle(theme.text)
                    Text("Sign in to continue")
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundStyle(theme.text.opacity(0.7))
                }
                .padding(.top, 40)
                
                VStack(spacing: 14) {
                    ThemedTextField(icon: "envelope.fill", placeholder: "Email", text: $email)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .keyboardType(.emailAddress)
                        .textContentType(.emailAddress)
                    ThemedTextField(icon: "lock.fill", placeholder: "Password", text: $password, isSecure: true)
                        .textContentType(.password)
                    
                    Button("Forgot password?") {
                        isResetSheetPresented = true
                    }
                    .font(.system(.footnote, design: .rounded).weight(.semibold))
                    .foregroundStyle(theme.primary)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                }
                .padding(20)
                .themedCard()
                
                Button(action: signIn) {
                    Group {
                        if isSubmitting {
                            ProgressView().tint(.white)
                        } else {
                            Text("Sign In")
                        }
                    }
                    .themedButton()
                }
                .disabled(isSubmitting)
                
                SocialSignInSection(role: nil)
                    .padding(.bottom, 24)
            }
            .padding(.horizontal, 24)
        }
        .scrollDismissesKeyboard(.interactively)
        .pawBackground()
        .onAppear {
            if email.isEmpty, let credentials = FirebaseEmulator.prefilledCredentials {
                email = credentials.email
                password = credentials.password
            }
        }
        .sheet(isPresented: $isResetSheetPresented) {
            PasswordResetSheet(email: email.trimmingCharacters(in: .whitespacesAndNewlines))
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
        .alert("Sign In Failed", isPresented: $showingAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
    }
    
    private func signIn() {
        let email = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !email.isEmpty, !password.isEmpty else {
            alertMessage = "Please enter your email and password."
            showingAlert = true
            return
        }
        // Local state only: the shared `isLoading` would replace this navigation stack with the splash screen.
        isSubmitting = true
        authService.signIn(email: email, password: password) { result in
            switch result {
            case .success(let user):
                userId = user.uid
                // MainAppView switches to ContentView once the profile is loaded.
                userProfileService.fetchUserProfile(uid: user.uid) { result in
                    DispatchQueue.main.async {
                        isSubmitting = false
                        if case .failure(let error) = result {
                            alertMessage = "No profile was found for this account. \(error.localizedDescription)"
                            showingAlert = true
                            try? authService.signOut()
                        }
                    }
                }
            case .failure(let error):
                isSubmitting = false
                alertMessage = error.localizedDescription
                showingAlert = true
            }
        }
    }
}

/// Asks for the account's email and sends a password reset link.
struct PasswordResetSheet: View {
    @State var email: String
    @EnvironmentObject var authService: AuthService
    @Environment(\.dismiss) private var dismiss
    @State private var isSending = false
    @State private var sentTo: String?
    @State private var errorMessage: String?
    private let theme = AppTheme.current
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 18) {
                if let sentTo {
                    Image(systemName: "envelope.badge.fill")
                        .font(.system(size: 50))
                        .foregroundStyle(theme.primary)
                    Text("Check your inbox")
                        .font(.system(.title3, design: .rounded).weight(.bold))
                        .foregroundStyle(theme.text)
                    Text("If an account exists for \(sentTo), we've sent a link to reset your password. It can take a few minutes; check your spam folder too.")
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundStyle(theme.text.opacity(0.7))
                        .multilineTextAlignment(.center)
                    Button("Back to sign in") { dismiss() }
                        .themedButton()
                } else {
                    Text("Enter the email you signed up with and we'll send you a link to choose a new password.")
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundStyle(theme.text.opacity(0.75))
                        .multilineTextAlignment(.center)
                    ThemedTextField(icon: "envelope.fill", placeholder: "Email", text: $email)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .keyboardType(.emailAddress)
                        .textContentType(.emailAddress)
                    if let errorMessage {
                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundStyle(.red)
                    }
                    Button(action: send) {
                        Group {
                            if isSending {
                                ProgressView().tint(.white)
                            } else {
                                Text("Send reset link")
                            }
                        }
                        .themedButton()
                    }
                    .disabled(isSending)
                    Text("Signed up with Apple or Google? Use those buttons on the sign-in screen instead.")
                        .font(.caption)
                        .foregroundStyle(theme.text.opacity(0.55))
                        .multilineTextAlignment(.center)
                }
            }
            .padding(24)
            .frame(maxHeight: .infinity, alignment: .top)
            .background(theme.background.ignoresSafeArea())
            .navigationTitle("Reset password")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
    
    private func send() {
        let address = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard address.contains("@"), address.contains(".") else {
            errorMessage = "Enter a valid email address."
            return
        }
        errorMessage = nil
        isSending = true
        Task {
            do {
                try await authService.sendPasswordReset(to: address)
                withAnimation { sentTo = address }
            } catch let error as NSError where error.code == AuthErrorCode.userNotFound.rawValue {
                // Don't reveal whether an account exists for this address.
                withAnimation { sentTo = address }
            } catch {
                errorMessage = error.localizedDescription
            }
            isSending = false
        }
    }
}

struct SignInView_Previews: PreviewProvider {
    static var previews: some View {
        SignInView(isLoading: .constant(false), userId: .constant("9FFPiZroJ2Nb9zneZer9NDleUpM2"), role: "Owner")
            .environmentObject(AuthService())
            .environmentObject(UserProfileService(authService: AuthService()))
            .environmentObject(NavigationPathManager())
            .environmentObject(MessagingService())
            .environmentObject(StorageService())
            .environmentObject(FirestoreService())
    }
}

//import SwiftUI
//
//struct SignInView: View {
//    @ObservedObject var viewModel: SigninViewModel
//    
//    var body: some View {
//        ZStack {
//            // Background with leaves
//            Image("leaves_background")
//                .resizable()
//                .scaledToFill()
//                .edgesIgnoringSafeArea(.all)
//
//            VStack(spacing: 20) {
//                Spacer()
//
//                // Welcome Text
//                VStack(spacing: 8) {
//                    Text("Welcome Back")
//                        .font(.largeTitle)
//                        .fontWeight(.bold)
//                        .foregroundColor(Color("DarkGreen"))
//
//                    Text("Login to your account")
//                        .font(.body)
//                        .foregroundColor(.gray)
//                }
//
//                // Text Fields
//                VStack(spacing: 16) {
//                    CustomTextField(icon: "person.fill", placeholder: "Full Name", text: $viewModel.fullName)
//                    CustomSecureField(icon: "lock.fill", placeholder: "Password", text: $viewModel.password)
//                }
//                .padding(.horizontal, 20)
//
//                // Remember Me and Forgot Password
//                HStack {
//                    Toggle("Remember Me", isOn: $viewModel.rememberMe)
//                        .toggleStyle(CheckboxToggleStyle())
//                        .foregroundColor(.gray)
//                        .font(.subheadline)
//
//                    Spacer()
//
//                    Button(action: {
//                        viewModel.forgotPassword()
//                    }) {
//                        Text("Forgot Password ?")
//                            .foregroundColor(Color("DarkGreen"))
//                            .font(.subheadline)
//                    }
//                }
//                .padding(.horizontal, 20)
//
//                // Login Button
//                Button(action: {
//                    viewModel.login()
//                }) {
//                    Text("Login")
//                        .font(.headline)
//                        .foregroundColor(.white)
//                        .frame(maxWidth: .infinity)
//                        .padding()
//                        .background(Color("DarkGreen"))
//                        .cornerRadius(10)
//                        .shadow(color: .gray.opacity(0.3), radius: 10, x: 0, y: 5)
//                }
//                .padding(.horizontal, 20)
//
//                Spacer()
//
//                // Sign Up Text
//                HStack {
//                    Text("Don’t have an account?")
//                        .foregroundColor(.gray)
//                    
//                    Button(action: {
//                        viewModel.signUp()
//                    }) {
//                        Text("Sign up")
//                            .foregroundColor(Color("DarkGreen"))
//                            .fontWeight(.bold)
//                    }
//                }
//                .font(.footnote)
//
//                Spacer(minLength: 40)
//            }
//        }
//    }
//}
//
//struct CustomTextField: View {
//    let icon: String
//    let placeholder: String
//    @Binding var text: String
//
//    var body: some View {
//        HStack {
//            Image(systemName: icon)
//                .foregroundColor(.gray)
//
//            TextField(placeholder, text: $text)
//                .font(.body)
//                .padding(10)
//        }
//        .background(Color.white.opacity(0.8))
//        .cornerRadius(10)
//        .overlay(
//            RoundedRectangle(cornerRadius: 10)
//                .stroke(Color.gray.opacity(0.5))
//        )
//    }
//}
//
//struct CustomSecureField: View {
//    let icon: String
//    let placeholder: String
//    @Binding var text: String
//
//    var body: some View {
//        HStack {
//            Image(systemName: icon)
//                .foregroundColor(.gray)
//
//            SecureField(placeholder, text: $text)
//                .font(.body)
//                .padding(10)
//        }
//        .background(Color.white.opacity(0.8))
//        .cornerRadius(10)
//        .overlay(
//            RoundedRectangle(cornerRadius: 10)
//                .stroke(Color.gray.opacity(0.5))
//        )
//    }
//}
//
//struct CheckboxToggleStyle: ToggleStyle {
//    func makeBody(configuration: Configuration) -> some View {
//        Button(action: {
//            configuration.isOn.toggle()
//        }) {
//            HStack {
//                Image(systemName: configuration.isOn ? "checkmark.square.fill" : "square")
//                    .foregroundColor(configuration.isOn ? Color("DarkGreen") : .gray)
//                configuration.label
//            }
//        }
//        .buttonStyle(PlainButtonStyle())
//    }
//}
//
//struct SignInView_Previews: PreviewProvider {
//    static var previews: some View {
//        SignInView(viewModel: SigninViewModel(isLoading: .constant(true)))
//            .preferredColorScheme(.light)
//    }
//}



