import SwiftUI

struct FavoriteButton: View {
    let isFavorite: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: isFavorite ? "heart.fill" : "heart")
                .foregroundColor(isFavorite ? .red : .gray)
                .padding(8)
                .background(Color.white)
                .clipShape(Circle())
                .shadow(radius: 3)
        }
    }
} 
