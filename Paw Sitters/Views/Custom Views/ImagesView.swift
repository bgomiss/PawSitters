//
//  ImagesView.swift
//  Paw Sitters
//
//  Created by aycan duskun on 6.09.2024.
//

import SwiftUI

// MARK: - ImageView
struct ImagesView: View {
    
    let listing: PetSittingListing
    var role: String?
    @State private var favoriteListings: Set<String> = []
    @ObservedObject var firestoreService: FirestoreService
    @ObservedObject var imageCache: ImageCacheViewModel

    var body: some View {
        VStack(alignment: .leading) {
            if let imageUrl = listing.imageUrls?.first, let url = URL(string: imageUrl) {
                if let image = imageCache.images[imageUrl] {
                    ZStack(alignment: .topTrailing) {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(maxWidth: .infinity, maxHeight: 200)
                            .clipped()
                            .cornerRadius(10)
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
                            toggleFavorite(for: listing)
                        }
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
            }
            
        }
        .onReceive(firestoreService.$listings) { _ in
            syncFavoritesWithFirestore()
        }
    }
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
