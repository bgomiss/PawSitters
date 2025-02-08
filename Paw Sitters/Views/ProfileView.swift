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
                ZStack {
                    VStack {
                        Text("\(name)")
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
                    
                    // Animal Icons
                            Group {
                                Image(systemName: "pawprint.fill")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 30, height: 30)
                                    .foregroundColor(.orange)
                                    .offset(x: -20, y: -110)

                                Image(systemName: "hare.fill")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 25, height: 25)
                                    .foregroundColor(.purple)
                                    .offset(x: 70, y: -30)

                                Image(systemName: "tortoise.fill")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 25, height: 25)
                                    .foregroundColor(.green)
                                    .offset(x: -120, y: 40)

                                Image(systemName: "bird.fill")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 25, height: 25)
                                    .foregroundColor(.blue)
                                    .offset(x: 90, y: 110)
                        }
                    }
                .frame(maxWidth: .infinity)
                .modifier(CollapsibleDestinationViewModifier())
                
//                .background(Color.blue)
//                .foregroundColor(.white)
//                .cornerRadius(15)
//                .padding()
                // Profile Details
                VStack(spacing: 20) {
                    
                    Text(bio)
                        .modifier(CollapsibleDestinationViewModifier())
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.horizontal)
                    HStack {
                        Image(systemName: "mappin.and.ellipse.circle.fill")
                            .foregroundColor(.red)
                    Text(location)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.horizontal)
                    }
                    .modifier(CollapsibleDestinationViewModifier())

                }
               // .modifier(CollapsibleDestinationViewModifier())
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
                        .modifier(CollapsibleDestinationViewModifier())
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
            ImagePicker(images: $images, isForMessaging: false)
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






