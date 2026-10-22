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
    @Environment(\.dismiss) private var dismiss
    // Edits happen on drafts so Cancel really discards them.
    @State private var draftName = ""
    @State private var draftBio = ""
    @State private var draftAge = ""
    @State private var draftLocation = ""
    @State private var isSaving = false
    @State private var errorMessage: String?
    @FocusState private var focusedField: Field?
    private let theme = AppTheme.current

    private enum Field: Hashable {
        case name, bio, age, location
    }

    private var hasChanges: Bool {
        draftName != name || draftBio != bio || draftAge != age || draftLocation != location
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    VStack(spacing: 12) {
                        labeledField("Name", icon: "person.fill") {
                            TextField("Your name", text: $draftName)
                                .textContentType(.name)
                                .focused($focusedField, equals: .name)
                                .submitLabel(.next)
                                .onSubmit { focusedField = .bio }
                        }
                        labeledField("About you", icon: "text.alignleft") {
                            TextField(role == "Sitter" ? "Your experience with pets" : "Tell sitters about your home and pets",
                                      text: $draftBio, axis: .vertical)
                                .lineLimit(3...6)
                                .focused($focusedField, equals: .bio)
                        }
                        HStack(spacing: 12) {
                            labeledField("Age", icon: "number") {
                                TextField("Age", text: $draftAge)
                                    .keyboardType(.numberPad)
                                    .focused($focusedField, equals: .age)
                            }
                            .frame(maxWidth: 120)
                            labeledField("Location", icon: "mappin.and.ellipse") {
                                TextField("City", text: $draftLocation)
                                    .textContentType(.addressCity)
                                    .focused($focusedField, equals: .location)
                                    .submitLabel(.done)
                                    .onSubmit { focusedField = nil }
                            }
                        }
                    }
                    .padding(16)
                    .themedCard()

                    if let errorMessage {
                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundStyle(.red)
                    }
                }
                .padding(20)
            }
            .scrollDismissesKeyboard(.interactively)
            .background(theme.background.ignoresSafeArea())
            .safeAreaInset(edge: .bottom) {
                Button(action: save) {
                    Group {
                        if isSaving {
                            ProgressView().tint(.white)
                        } else {
                            Text("Save changes")
                        }
                    }
                    .themedButton(hasChanges ? theme.primary : theme.primary.opacity(0.4))
                    .frame(maxWidth: .infinity)
                }
                .disabled(!hasChanges || isSaving)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(.ultraThinMaterial)
            }
            .navigationTitle("Edit profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") { focusedField = nil }
                        .fontWeight(.semibold)
                }
            }
        }
        .interactiveDismissDisabled(hasChanges)
        .onAppear {
            draftName = name
            draftBio = bio
            draftAge = age
            draftLocation = location
        }
    }

    private func labeledField<Content: View>(_ title: String, icon: String,
                                             @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(title, systemImage: icon)
                .font(.system(.caption, design: .rounded).weight(.semibold))
                .foregroundStyle(theme.text.opacity(0.6))
            content()
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(theme.background, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
    }

    private func save() {
        focusedField = nil
        guard let userProfile = userProfileService.userProfile else {
            errorMessage = "Your profile couldn't be loaded. Try again."
            return
        }
        let trimmedName = draftName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            errorMessage = "Please enter your name."
            return
        }
        isSaving = true
        errorMessage = nil

        let updatedProfile = UserProfile(
            id: userProfile.id,  // Ensure ID is passed
            email: userProfile.email,
            name: trimmedName,
            profileImageUrl: userProfile.profileImageUrl,
            description: draftBio.trimmingCharacters(in: .whitespacesAndNewlines),
            role: role,
            age: draftAge.trimmingCharacters(in: .whitespacesAndNewlines),
            location: draftLocation.trimmingCharacters(in: .whitespacesAndNewlines),
            emailVerified: userProfile.emailVerified
        )

        let collection = role == "Sitter" ? "sitters" : "owners"
        userProfileService.updateUserProfile(updatedProfile, in: collection) { result in
            DispatchQueue.main.async {
                isSaving = false
                switch result {
                case .success():
                    name = updatedProfile.name ?? ""
                    bio = updatedProfile.description ?? ""
                    age = updatedProfile.age ?? ""
                    location = updatedProfile.location ?? ""
                    userProfileService.userProfile = updatedProfile
                    dismiss()
                case .failure(let error):
                    errorMessage = "Couldn't save your changes: \(error.localizedDescription)"
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
