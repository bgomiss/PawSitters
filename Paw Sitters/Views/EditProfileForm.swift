//
//  EditProfileForm.swift
//  Paw Sitters
//
//  Created by aycan duskun on 29.06.2024.
//

import SwiftUI

struct EditProfileForm: View {
    @Binding var name: String
    @Binding var bio: String
    @Binding var age: String
    @Binding var location: String
    var role: String
    @EnvironmentObject var userProfileService: UserProfileService
    @Environment(\.presentationMode) var presentationMode
    @State private var showingSuccessAlert = false
    @State private var showingErrorAlert = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Profile Information")) {
                    TextField("Name", text: $name)
                    TextField("Bio", text: $bio)
                    TextField("Age", text: $age)
                    TextField("Location", text: $location)
                }
                
                Button("I am done") {
                    updateUserProfile()
                }
                .alert(isPresented: $showingSuccessAlert) {
                    Alert(
                        title: Text("Success"),
                        message: Text("Profile updated successfully."),
                        dismissButton: .default(Text("OK")) {
                            presentationMode.wrappedValue.dismiss()
                        }
                    )
                }
                .alert(isPresented: $showingErrorAlert) {
                    Alert(
                        title: Text("Error"),
                        message: Text(errorMessage),
                        dismissButton: .default(Text("OK"))
                    )
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarItems(trailing: Button("Cancel") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
    
    private func updateUserProfile() {
        guard let userProfile = userProfileService.userProfile else {
            errorMessage = "User profile not found"
            showingErrorAlert = true
            return
        }
        
        let updatedProfile = UserProfile(
            id: userProfile.id,  // Ensure ID is passed
            email: userProfile.email,
            name: name,
            profileImageUrl: userProfile.profileImageUrl,
            description: bio,
            role: role,
            age: age,
            location: location
        )
        
        let collection = role == "Sitter" ? "sitters" : "owners"
        userProfileService.updateUserProfile(updatedProfile, in: collection) { result in
            switch result {
            case .success():
                DispatchQueue.main.async {
                    showingSuccessAlert = true
                }
            case .failure(let error):
                DispatchQueue.main.async {
                    errorMessage = error.localizedDescription
                    showingErrorAlert = true
                }
            }
        }
    }
}

struct EditProfileForm_Previews: PreviewProvider {
    static var previews: some View {
        EditProfileForm(name: .constant(""), bio: .constant(""), age: .constant(""), location: .constant(""), role: "Sitter")
            .environmentObject(UserProfileService(authService: AuthService()))
    }
}


