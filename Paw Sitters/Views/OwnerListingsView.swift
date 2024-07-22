//
//  OwnerListingsView.swift
//  Paw Sitters
//
//  Created by aycan duskun on 21.06.2024.
//

//import SwiftUI
//
//struct OwnerListingsView: View {
//    @Binding var userId: String
//    @Binding var receiverId: String
//    @EnvironmentObject var firestoreService: FirestoreService
//    @EnvironmentObject var userProfileService: UserProfileService
//    @State private var listings: [PetSittingListing] = []
//    @State private var loading = true
//    
//    var body: some View {
//        VStack {
//            if loading {
//                Text("Loading listings...")
//                    .font(.headline)
//                    .padding()
//            } else if listings.isEmpty {
//                Text("No listings available.")
//                    .font(.headline)
//                    .padding()
//            } else {
//                List(listings) { listing in
//                    NavigationLink(destination: ListingDetailView(listing: listing, userId: $userId, receiverId: $receiverId)) {
//                        HStack {
//                            if let imageUrl = listing.imageUrl, let url = URL(string: imageUrl) {
//                                AsyncImage(url: url)
//                                    .aspectRatio(contentMode: .fill)
//                                    .frame(width: 50, height: 50)
//                                    .clipShape(Circle())
//                            }
//                            Text(listing.title)
//                        }
//                    }
//                }
//            }
//        }
//        .onAppear {
//            fetchListings()
//        }
//    }
//    
//    private func fetchListings() {
//        if let role = userProfileService.userProfile?.role {
//            firestoreService.fetchListings(for: role == "Sitter" ? "Owner" : "Sitter") { result in
//                switch result {
//                case .success(let fetchedListings):
//                    self.listings = fetchedListings
//                    self.loading = false
//                    print("Fetched listings: \(fetchedListings)")
//                case .failure(let error):
//                    self.loading = false
//                    print("Error fetching listings: \(error.localizedDescription)")
//                }
//            }
//        }
//    }
//}
//
//struct OwnerListingsView_Previews: PreviewProvider {
//    static var previews: some View {
//        OwnerListingsView(userId: .constant("9FFPiZroJ2Nb9zneZer9NDleUpM2"), receiverId: .constant("HZHDnLPFWfftcb3e0Mjz4DIoYZn2"))
//            .environmentObject(FirestoreService())
//            .environmentObject(UserProfileService())
//    }
//}



