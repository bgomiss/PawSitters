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
    var role: String
    
    var body: some View {
        ScrollView {
            VStack {
                // Profile Header
                VStack {
                    Text("\(name)'s Profile")
                        .font(.largeTitle)
                        .bold()
                        .padding(.top, 40)
                    
                    if let imageUrl = userProfileService.userProfile?.profileImageUrl, let url = URL(string: imageUrl) {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .empty:
                                ProgressView()
                            case .success(let image):
                                image
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 150, height: 150)
                                    .clipShape(Circle())
                                    .overlay(Circle().stroke(Color.white, lineWidth: 4))
                                    .shadow(radius: 10)
                                    .padding(.top, 20)
                            case .failure:
                                Image(systemName: "person.fill")
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 150, height: 150)
                                    .clipShape(Circle())
                                    .overlay(Circle().stroke(Color.white, lineWidth: 4))
                                    .shadow(radius: 10)
                                    .padding(.top, 20)
                            @unknown default:
                                EmptyView()
                            }
                        }
                    } else {
                        Button("Select Profile Image") {
                            showingImagePicker = true
                        }
                        .padding()
                    }
                }
                .modifier(CollapsibleDestinationViewModifier())
//                .frame(maxWidth: .infinity)
//                .background(Color.blue)
//                .foregroundColor(.white)
//                .cornerRadius(15)
//                .padding()
                // Profile Details
            VStack(spacing: 20) {
                    TextField("Name", text: $name)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.horizontal)
                    
                    TextField("Bio", text: $bio)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.horizontal)
                    
                    TextField("Age", text: $age)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.horizontal)
                    
                    TextField("Location", text: $location)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.horizontal)
                }
                .padding(.top, 20)
                
                // Update Info Button
                Button(action: {
                    showingEditForm = true
                }) {
                    Text("Edit Profile")
                        .modifier(CollapsibleDestinationViewModifier())
                        .foregroundStyle(.green)
                        .fontWeight(.semibold)
//                        .padding()
//                        .frame(maxWidth: .infinity)
//                        .background(Color.blue)
//                        .foregroundColor(.white)
//                        .cornerRadius(10)
//                        .shadow(radius: 5)
                }
                .padding()
                
                Button(action: {
                    do {
                        try authService.signOut()
                        navigationPathManager.popToRoot() // Clear the navigation stack
                    } catch let error {
                        print("Error signing out: \(error.localizedDescription)")
                    }
                }) {
                    Text("Sign Out")
                        .padding()
                        .background(Color.clear)
                        .foregroundColor(.red)
                        .cornerRadius(8)
                }
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
            ImagePicker(images: $images)
        }
        .sheet(isPresented: $showingEditForm) {
            EditProfileForm(name: $name, bio: $bio, age: $age, location: $location, role: role)
                .environmentObject(userProfileService)
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






