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



