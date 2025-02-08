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
    @State private var isPresenting = false
    @State private var role: String?
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var userProfileService: UserProfileService
    @EnvironmentObject var messagingService: MessagingService
    @EnvironmentObject var storageService: StorageService
    @EnvironmentObject var firestoreService: FirestoreService
    @EnvironmentObject var navigationPathManager: NavigationPathManager
    @StateObject private var viewModel: SigninViewModel
    @Environment(\.presentationMode) var presentationMode

    
    init(isLoading: Binding<Bool>, userId: Binding<String>, role: String) {
        self.role = role
        self._isLoading = isLoading
        self._userId = userId
        _viewModel = StateObject(wrappedValue: SigninViewModel(isLoading: isLoading))
     }
    
    var body: some View {
   //     NavigationStack(path: $navigationPathManager.path) {
            VStack {
                Text("Sign In")
                    .font(.largeTitle)
                    .padding()
                Spacer()
                
                TextField("Email", text: $email)
                    .autocapitalization(.none)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                
                SecureField("Password", text: $password)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                Spacer()
                
                Button(action: {
                    viewModel.isLoading = true
                    authService.signIn(email: email, password: password) { result in
                        switch result {
                        case .success(let user):
                            viewModel.determineRoleAndFetchUserProfile(user)
                            viewModel.isLoading = false
                            isPresenting.toggle()
                         case .failure(let error):
                            print("Error signing in: \(error.localizedDescription)")
                            viewModel.isLoading = false
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
            .onAppear {
                viewModel.messagingService = messagingService
                viewModel.storageService = storageService
                viewModel.userProfileService = userProfileService
                viewModel.authService = authService
                viewModel.firestoreService = firestoreService
                viewModel.navigationPathManager = navigationPathManager
            }
//            .alert(isPresented: $viewModel.showingAlert) {
//                Alert(title: Text(viewModel.alertTitle),
//                      message: Text(viewModel.alertMessage),
//                      dismissButton: .default(Text("OK")) {
//                    if viewModel.alertTitle == "Success" {
//                        presentationMode.wrappedValue.dismiss()
//                    }
//                })
//            }
//            .sheet(isPresented: $isPresenting) {
//                if let role = self.role {
//                    ContentView(isLoading: $isLoading, userId: $userId, firestoreService: firestoreService, messagingService: messagingService, storageService: storageService, role: role)
//                }
//            }
//            .navigationDestination(for: NavigationDestination.self) { destination in
//                switch destination {
//                case .contentView:
//                    if let role = self.role {
//                        ContentView(isLoading: $isLoading, userId: $userId, firestoreService: firestoreService, messagingService: messagingService, storageService: storageService, role: role)
//                    }
//                default:
//                    Text("Guimel2")
//                }
//            }
        }
 //   }

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



