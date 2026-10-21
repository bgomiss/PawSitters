import SwiftUI

struct ListingCardView: View {
    let listing: PetSittingListing
    var role: String?
    @ObservedObject var imageCache: ImageCacheViewModel
    @EnvironmentObject var firestoreService: FirestoreService
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ImagesView(listing: listing, role: role, imageCache: imageCache)
                .frame(height: 200)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(listing.title)
                    .font(.headline)
                
                if let dateRange = listing.dateRange {
                    Text("Date: \(dateRange.lowerBound, style: .date) - \(dateRange.upperBound, style: .date)")
                        .font(.subheadline)
                }
                
                Text(listing.location ?? "")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            .padding(.horizontal, 8)
        }
        .background(Color.white)
        .cornerRadius(12)
        .shadow(radius: 5)
    }
} 
