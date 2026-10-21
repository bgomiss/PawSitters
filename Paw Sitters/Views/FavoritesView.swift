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
    @EnvironmentObject var firestoreService: FirestoreService
    @EnvironmentObject var storageService: StorageService
    @EnvironmentObject var messagingService: MessagingService
    @EnvironmentObject var userProfileService: UserProfileService
    @StateObject private var imageCache = ImageCacheViewModel()
    var role: String?
    
    var body: some View {
        // Shown inside ContentView's NavigationStack, so no stack of its own here.
        VStack {
                ScreenTitle("Favorites", icon: "heart.fill")
                
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(firestoreService.listings.filter { firestoreService.isFavorite($0) }) { listing in
                            NavigationLink(destination: ListingDetailView(listing: listing, userId: userId)) {
                                ListingCardView(listing: listing, role: listing.role, imageCache: imageCache)
                                    .padding(.horizontal)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical)
                }
                .overlay {
                    if firestoreService.favoriteIds.isEmpty {
                        EmptyStateView(icon: "heart.text.square.fill",
                                       title: "No favorites yet",
                                       message: "Tap the heart on a listing to save it here.")
                    }
                }
        }
    }
}
