//
//  CreateListingView.swift
//  Paw Sitters
//
//  Created by aycan duskun on 13.07.2024.
//

import SwiftUI

struct CreateListingView: View {
    
    @State private var name: String = ""
    @State private var requiredDates: String = ""
    @State private var location: String = ""
    @State private var startDate = Date()
    @State private var endDate = Date()
    var role: String?
    @State private var description: String = ""
    @State private var title: String = ""
    @State private var date = Date()
    @State private var images: [UIImage] = []
    @State private var listings = PetSittingListing(title: "", description: "", name: "", date: Date(), role: "", ownerId: "")
    @State private var showingAlert = false
    @State private var showingImagePicker = false
    @State private var isPresenting = false
    @State private var alertMessage = ""
    @State private var alertTitle = ""
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var firestoreService: FirestoreService
    @EnvironmentObject var storageService: StorageService
    @EnvironmentObject var userProfileService: UserProfileService
    @EnvironmentObject var navigationPathManager: NavigationPathManager
    @Environment(\.presentationMode) var presentationMode
    
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Please Enter The Details Below")) {
                    
                    TextField("Title", text: $title)
                    
                    TextField("Name&Surname", text: $name)
                    
                    TextField("Location", text: $location)
                    
                    ZStack(alignment: .topLeading) {
                        if description.isEmpty {
                            Text("Enter a description")
                                .foregroundColor(.gray)
                                .padding(.top, 8)
                                .padding(.horizontal, 4)
                        }
                        TextEditor(text: $description)
                            .frame(height: 150)
                            .onChange(of: description) {_, newValue in
                                if newValue.count > 150 {
                                    description = String(newValue.prefix(150))
                                }
                            }
                    }
                }
                if !images.isEmpty {
                    ScrollView(.horizontal) {
                        HStack {
                            ForEach(images, id: \.self) { image in
                                Image(uiImage: image)
                                    .resizable()
                                    .frame(width: 100, height: 100)
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                                    .padding(4)
                            }
                        }
                    }
                }
                
                Button("Choose Listing Images ") {
                    showingImagePicker = true
                }
                
                Button("Publish") {
                    uploadImagesAndPublishListing()
                }
                
                .alert(isPresented: $showingAlert) {
                    Alert(
                        title: Text(alertTitle),
                        message: Text(alertMessage),
                        dismissButton: .default(Text("OK")) {
                            presentationMode.wrappedValue.dismiss()
                        }
                    )
                }
                
                .navigationBarItems(leading: Text("Please Enter The Details Below")
                    .font(.custom("HelveticaNeue-Thin", size: 16))
                    .foregroundColor(.teal)
                    .fontWeight(.bold)
                )
                .navigationBarItems(trailing: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                })
                .sheet(isPresented: $showingImagePicker) {
                    ImagePicker(images: $images)
                }
            }
        }
    }
    
    private func uploadImagesAndPublishListing() {
        var imageUrls: [String] = []
        let dispatchGroup = DispatchGroup()
        
        for image in images {
            dispatchGroup.enter()
            storageService.uploadImage(image, path: "listing_images/\(UUID().uuidString).jpg") { result in
                switch result {
                case .success(let imageUrl):
                    imageUrls.append(imageUrl)
                case .failure(let error):
                    print("Error uploading image: \(error.localizedDescription)")
                }
                dispatchGroup.leave()
            }
        }
        
        dispatchGroup.notify(queue: .main) {
            self.publishListing(imageUrls: imageUrls)
        }
    }
    
    private func publishListing(imageUrls: [String]) {
        let ownerId = authService.user?.uid ?? ""
        listings = PetSittingListing(
            title: title,
            description: description,
            name: name,
            date: date,
            imageUrls: imageUrls,
            role: role ?? "Sitter",
            ownerId: ownerId
        )
        
        firestoreService.addListing(listings) { result in
            switch result {
            case .success():
                alertTitle = "Success"
                alertMessage = "Listing published successfully"
                showingAlert = true
                print("SAVED SUCCESSFULLY")
            case .failure(let error):
                alertTitle = "Error"
                alertMessage = error.localizedDescription
                showingAlert = true
                print(alertMessage)
            }
        }
    }
}

struct CreateListingView_Previews: PreviewProvider {
    static var previews: some View {
        CreateListingView(role: "Sitter")
        .environmentObject(UserProfileService(authService: AuthService()))
        .environmentObject(AuthService())
        .environmentObject(FirestoreService())
        .environmentObject(NavigationPathManager())
    }
}
