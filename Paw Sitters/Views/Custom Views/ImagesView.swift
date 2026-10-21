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
    @StateObject private var viewModel = ImageViewModel()
    @EnvironmentObject var firestoreService: FirestoreService
    @ObservedObject var imageCache: ImageCacheViewModel

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Group {
                if let imageUrl = listing.imageUrl {
                    if let image = imageCache.images[imageUrl] {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } else {
                        AppTheme.current.secondary.opacity(0.35)
                            .overlay(ProgressView().tint(AppTheme.current.primary))
                            .onAppear {
                                imageCache.loadImage(from: imageUrl)
                            }
                    }
                } else {
                    // No photo: a friendly themed placeholder instead of a grey box.
                    AppTheme.current.secondary.opacity(0.35)
                        .overlay(
                            Image(systemName: "pawprint.fill")
                                .font(.system(size: 44))
                                .foregroundStyle(AppTheme.current.primary.opacity(0.5))
                        )
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 180)
            .clipped()
            
            FavoriteButton(isFavorite: firestoreService.isFavorite(listing)) {
                firestoreService.toggleFavorite(listing)
            }
            .padding(10)
        }
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

// ViewModel for ImagesView
class ImageViewModel: ObservableObject {
    @Published var isFavorite = false
    
    func toggleFavorite() {
        isFavorite.toggle()
    }
}
