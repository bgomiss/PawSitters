//
//  BottomSheetView.swift
//  Paw Sitters
//
//  Created by aycan duskun on 29.08.2024.
//

import SwiftUI

struct BottomSheetView: View {
    var listing: PetSittingListing
    
    var body: some View {
        VStack {
            Capsule()
                .fill(Color.gray)
                .frame(width: 40, height: 5)
                .padding(.top, 8)
                .padding(.bottom, 10)
            
                VStack(alignment: .leading) {
                    // Listing Image
                    if let imageUrl = listing.imageUrls?.first, let url = URL(string: imageUrl) {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .empty:
                                ProgressView()
                                    .frame(maxWidth: .infinity, maxHeight: 200)
                            case .success(let image):
                                image
                                    .resizable()
                                    .scaledToFill()
                                    .frame(maxWidth: .infinity, maxHeight: 200)
                                    .clipped()
                            case .failure:
                                Image(systemName: "photo")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(maxWidth: .infinity, maxHeight: 200)
                            @unknown default:
                                EmptyView()
                            }
                        }
                        .cornerRadius(10)
                    }
                    
                    // Listing Title
                    Text(listing.title)
                        .font(.headline)
                        .padding([.top, .leading, .trailing])
                    
                    // Date Range
                    if let dateRange = listing.dateRange {
                        Text("Date: \(dateRange)")
                            .font(.headline)
                            .padding([.leading, .trailing])
                    } else {
                        Text("No Date selected")
                    }
                    
                    // Location
                    Text(listing.location ?? "")
                        .font(.headline)
                        .padding([.leading, .trailing])
                    
                    // Pet Information
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
                }
            
            .background(Color.white)
            .cornerRadius(20)
            .shadow(radius: 20)
        }
        .frame(maxWidth: .infinity)
        .edgesIgnoringSafeArea(.all)
        .padding()
    }
}

