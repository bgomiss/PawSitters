//
//  FavoritesView.swift
//  Paw Sitters
//
//  Created by aycan duskun on 26.08.2024.
//

import SwiftUI

struct FavoritesView: View {
    
    @Binding var userId: String
    @State private var favoriteListings: Set<String> = []
    @EnvironmentObject var navigationPathManager: NavigationPathManager
    @ObservedObject var firestoreService: FirestoreService
    @ObservedObject var messagingService: MessagingService
    @StateObject private var imageCache = ImageCacheViewModel()
    var role: String?

    var body: some View {
        NavigationStack(path: $navigationPathManager.path) {

        VStack {
            Text("FAVORITES")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .center)
                .fontWeight(.bold)
            
            ScrollView {
                ForEach(firestoreService.listings.filter { $0.isFavorite }) { listing in
                    NavigationLink(destination: ListingDetailView(listing: listing, userId: $userId, messagingService: messagingService)) {
                        VStack(alignment: .leading) {
                            if let imageUrl = listing.imageUrls?.first, let url = URL(string: imageUrl) {
                                if let image = imageCache.images[imageUrl] {
                                    ZStack(alignment: .topTrailing) {
                                        Image(uiImage: image)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(maxWidth: .infinity, maxHeight: 200)
                                            .clipped()
                                        ZStack {
                                            Circle()
                                                .fill(Color.white)
                                                .frame(width: 30, height: 30)
                                                .shadow(color: .black.opacity(0.7), radius: 5, x: 0, y: 0)
                                            Image(systemName: favoriteListings.contains(listing.id) ? "bolt.heart.fill" : "bolt.heart")
                                                .resizable()
                                                .foregroundStyle(favoriteListings.contains(listing.id) ? .pink : .black)
                                                .frame(width: 15, height: 15)
                                                .scaleEffect(favoriteListings.contains(listing.id) ? 1.2 : 1.0)
                                                .animation(.easeInOut(duration: 0.3), value: favoriteListings.contains(listing.id))
                                                .padding()
                                        }
                                        .onTapGesture {
                                            toggleFavorite(for: listing)                                         }
                                    }
                                } else {
                                ProgressView()
                                    .frame(maxWidth: .infinity, maxHeight: 200)
                                    .onAppear {
                                        imageCache.loadImage(from: url, for: imageUrl)
                                    }
                            }
                        } else {
                            Image(systemName: "dog")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 100, height: 100) // Adjust the size here
                                .foregroundColor(.gray) // Set the color to gray
                                .font(.system(size: 20, weight: .thin))
                            // .cornerRadius(10)
                        }
                    
                            
                            Text(listing.title)
                                .font(.headline)
                                .padding([.top, .leading, .trailing])
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            if let dateRange = listing.dateRange {
                                Text("Date: \(dateRange)")
                                    .font(.headline)
                                    .padding([.leading, .trailing])
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            } else {
                                Text("No Date selected")
                            }
                            
                            Text(listing.location ?? "")
                                .font(.headline)
                                .padding([.leading, .trailing])
                                .frame(maxWidth: .infinity, alignment: .leading)
                            HStack {
                                if let pet = listing.pets {
                                    if let dogs = pet.numDogs {
                                        Image(systemName: "dog.fill")
                                        Text(dogs)
                                    }
                                    if let hares = pet.numHares {
                                        Image(systemName: "hare.fill")
                                        Text(hares)
                                    }
                                    if let birds = pet.numBirds {
                                        Image(systemName: "bird.fill")
                                        Text(birds)
                                    }
                                    if let others = pet.numOthers {
                                        Image(systemName: "pawprint.fill")
                                        Text(others)
                                    }
                                }
                            }
                            .padding([.leading, .trailing])
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .background(Rectangle().fill(Color.white).shadow(radius: 1))
                    .cornerRadius(10)
                    .padding(.vertical, 5)
                    .padding(.horizontal, 15)
                }
            }
            .onReceive(firestoreService.$listings) { _ in
                syncFavoritesWithFirestore()
            }
        }
    }
}
//            .onAppear {
//                if let user = authService.user {
//                    userProfileService.fetchUserProfile(uid: user.uid) { result in
//                        switch result {
//                        case .success(let profile):
//                            DispatchQueue.main.async {
//                                userProfileService.userProfile = profile
//                                firestoreService.fetchListings(for: profile.role)
//                            }
//                        case .failure(let error):
//                            print("Error fetching user profile: \(error.localizedDescription)")
//                            isLoading = false
//                        }
//                    }
//                }
//            }
            
    private func toggleFavorite(for listing: PetSittingListing) {
        if favoriteListings.contains(listing.id) {
            favoriteListings.remove(listing.id)
            firestoreService.updateFavoriteStatus(role: self.role ?? "Sitter", for: listing.id, isFavorite: false)
        } else {
            favoriteListings.insert(listing.id)
            firestoreService.updateFavoriteStatus(role: self.role ?? "Sitter", for: listing.id, isFavorite: true)
        }
    }

    private func syncFavoritesWithFirestore() {
        for listing in firestoreService.listings {
            if listing.isFavorite {
                favoriteListings.insert(listing.id)
            } else {
                favoriteListings.remove(listing.id)
            }
        }
    }
}
        
    

#Preview {
    FavoritesView(userId: .constant("9FFPiZroJ2Nb9zneZer9NDleUpM2"), firestoreService: FirestoreService(), messagingService: MessagingService())
}
