//
//  SignUpView.swift
//  Paw Sitters
//
//  Created by aycan duskun on 21.06.2024.
//

import SwiftUI

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
    @State private var isPresenting = false
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var userProfileService: UserProfileService
    @EnvironmentObject var storageService: StorageService
    @EnvironmentObject var navigationPathManager: NavigationPathManager
    @ObservedObject var messagingService: MessagingService
    @ObservedObject var firestoreService: FirestoreService
    
    var role: String
    
    var body: some View {
        VStack {
            Text("Sign Up as \(role)")
                .font(.largeTitle)
                .padding()
            TextField("Name", text: $name)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            TextField("Title", text: $title)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            TextField("Description", text: $description)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            TextField("Age", text: $age)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            TextField("Location", text: $location)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            TextField("Email", text: $email)
                .autocapitalization(.none)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            SecureField("Password", text: $password)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            if let image = images.first {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 50, height: 50)
                    .clipShape(Circle())
                    //.padding()
            }
            Button("Select Profile Image") {
                showingImagePicker = true
            }
            .padding()
            Button(action: {
                isPresenting = true
                authService.signUp(email: email, password: password) { result in
                    switch result {
                    case .success(let user):
                        print("User signed up: \(user.email ?? "")")
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
                    case .failure(let error):
                        print("Error signing up: \(error.localizedDescription)")
                    }
                }
            }) {
                Text("Sign Up")
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
        }
        .onAppear{
            print("ROLE IS: \(self.role)")
        }
        .fullScreenCover(isPresented: $isPresenting, content: {
            ContentView(isLoading: $isLoading, userId: $userId, firestoreService: firestoreService, messagingService: messagingService, role: self.role)
            .environmentObject(authService)
            .environmentObject(userProfileService)
            .environmentObject(storageService)
    })
        .padding()
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(images: $images)
        }
    }
    
    private func saveUserProfile(_ uid: String, imageUrl: String?) {
        let profile = UserProfile(id: uid, email: email, name: name, profileImageUrl: imageUrl, description: description, role: role, age: age, location: location)
            let collection = role == "Sitter" ? "sitters" : "owners"
            userProfileService.addUserProfile(profile, to: collection, uid: uid) { result in
                switch result {
                case .success():
                    userProfileService.fetchUserProfile(uid: uid) { result in
                        switch result {
                        case .success(let profile):
                            DispatchQueue.main.async {
                                userProfileService.userProfile = profile
                                isPresenting = true
                            }
                        case .failure(let error):
                            print("Error fetching user profile after saving: \(error.localizedDescription)")
                        }
                    }
                case .failure(let error):
                    print("Error adding user profile: \(error.localizedDescription)")
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
















