//
//  ContentView.swift
//  Paw Sitters
//
//  Created by aycan duskun on 21.06.2024.
//
import SwiftUI

struct ContentView: View {
    @Binding var isLoading: Bool
    @Binding var userId: String
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var firestoreService: FirestoreService
    @EnvironmentObject var userProfileService: UserProfileService
    @ObservedObject var messagingService: MessagingService
    @EnvironmentObject var navigationPathManager: NavigationPathManager
    @State private var listings: [PetSittingListing] = []
    @State private var isFullScreenCoverPresented = false
    
    var didSelectNewUser: (String) -> () = { _ in }

    var role: String?
    
    var body: some View {
        NavigationStack(path: $navigationPathManager.path) {
            VStack {
                Text("PAWSITTERS")
                    .font(.headline)
                    .padding(.top, -30)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .fontWeight(.bold)
                if isLoading {
                    Text("Loading listings...")
                        .font(.headline)
                        .padding()
                } else if listings.isEmpty {
                    Text("No listings available.")
                        .font(.headline)
                        .padding()
                } else {
                    List(listings) { listing in
                        NavigationLink(destination: ListingDetailView(listing: listing, userId: $userId)) {
                            VStack(alignment: .leading) {
                                
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

                               Button(action: {
                                    didSelectNewUser(listing.ownerId)
                                }) {
                                    Text(listing.title)
                                        .font(.headline)
                                        .padding([.top, .leading, .trailing])
                                        .frame(maxWidth: .infinity, alignment: .leading)
                              }
                                .buttonStyle(PlainButtonStyle())
                                Text("14 Jul - 30 Aug 2024")
                                    .font(.headline)
                                    .padding([.leading, .trailing])
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                Text(listing.location ?? "")
                                    .font(.headline)
                                    .padding([.leading, .trailing])
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                HStack {
                                    Image(systemName: "bird.fill")
                                    Text("1")
                                    Image(systemName: "hare.fill")
                                    Text("4")
                                    Image(systemName: "fish.fill")
                                    Text("2")
                                }
                                .padding([.leading, .trailing])
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                        }
                            .background(Rectangle().fill(Color.white).shadow(radius: 1))
                            .cornerRadius(10)
                            .padding(.vertical, 5)
                    }
                }
            }
                
                Spacer()
                
                Button(action: {
                    do {
                        try authService.signOut()
                        navigationPathManager.popToRoot() // Clear the navigation stack
                        isLoading = false
                    } catch let error {
                        print("Error signing out: \(error.localizedDescription)")
                    }
                }) {
                    Text("Sign Out")
                        .padding()
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            }
          //  .navigationBarTitle("PAWSITTERS")
            .navigationBarItems(
                leading: HStack {
                    Image(systemName: "person.crop.circle")
                        .onTapGesture {
                            navigationPathManager.push(.profileView)
                            print("Image tapped!")
                        }
                },
                trailing: HStack {
                    Image(systemName: "message")
                        .onTapGesture {
                            isFullScreenCoverPresented.toggle()
                        }
                }
            )
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Button(action: {
                        withAnimation(.snappy) {
                            navigationPathManager.push(.createListingView)
                        }
                    }) {
                        Text("Post Your Own Listing")
                            .padding(.horizontal)
                            .frame(height: 30)
                            .background(Color.indigo)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                }
            }
            .navigationDestination(for: NavigationDestination.self) { destination in
                switch destination {
                case .profileView:
                    ProfileView(role: role ?? "Sitter")
                case .conversationsView:
                    ConversationsView(messagingService: messagingService, userId: $userId)
                case .createListingView:
                    CreateListingView(role: role)
                default:
                    Text("GuimelContentView")
                }
            }
            .onAppear {
                if let user = authService.user {
                    userProfileService.fetchUserProfile(uid: user.uid) { result in
                        switch result {
                        case .success(let profile):
                            userProfileService.userProfile = profile
                            fetchData(role: profile.role) // Use the role from the fetched profile
                        case .failure(let error):
                            print("Error fetching user profile: \(error.localizedDescription)")
                            isLoading = false
                        }
                    }
                }
            }
            .fullScreenCover(isPresented: $isFullScreenCoverPresented) {
                ConversationsView(messagingService: messagingService, userId: $userId)
            }
        }
    }
    
    func fetchData(role: String) {
        firestoreService.fetchListings(for: role) { result in
            switch result {
            case .success(let fetchedListings):
                self.listings = fetchedListings
                self.isLoading = false
            case .failure(let error):
                self.isLoading = false
                print("Error fetching listings: \(error.localizedDescription)")
            }
        }
    }
}

struct ListingDetailView: View {
    var listing: PetSittingListing
    @Binding var userId: String
    @EnvironmentObject var authService: AuthService
    @State private var selectedImageIndex: Int? = nil
    @State private var showingImageDetail = false

    var body: some View {
        VStack {
            Text(listing.title)
                .font(.largeTitle)
                .padding()
            
            if let imageUrls = listing.imageUrls, !imageUrls.isEmpty {
                TabView {
                    ForEach(imageUrls.indices, id: \.self) { index in
                        AsyncImage(url: URL(string: imageUrls[index])) { phase in
                            switch phase {
                            case .empty:
                                ProgressView()
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(maxWidth: .infinity, maxHeight: 300)
                                    .onTapGesture {
                                        self.selectedImageIndex = index
                                        self.showingImageDetail = true
                                    }
                            case .failure:
                                Image(systemName: "photo")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(maxWidth: .infinity, maxHeight: 300)
                            @unknown default:
                                EmptyView()
                            }
                        }
                        .tag(index)
                    }
                }
                .frame(height: 300)
                .tabViewStyle(PageTabViewStyle())
                .fullScreenCover(isPresented: $showingImageDetail) {
                    ImageDetailView(imageUrls: imageUrls, selectedImageIndex: $selectedImageIndex)
                }
            }
            
            Text(listing.description)
                .padding()
            Text("Owner: \(listing.name)")
                .padding()
            if let dateRange = listing.dateRange {
                Text("Date: \(formattedDateRange(dateRange))")
                    .padding()
            } else {
                Text("No Date selected")
            }
            // NavigationLink to MessagingView
            NavigationLink(destination: MessagingView(userId: $userId, receiverId: listing.ownerId)) {
                
                Text("Contact")
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            .padding(.top, 10)
        }
    }
    private func formattedDateRange(_ range: ClosedRange<Date>) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        
        let startDate = formatter.string(from: range.lowerBound)
        let endDate = formatter.string(from: range.upperBound)
        
        return "\(startDate) - \(endDate)"
    }
}

struct ImageDetailView: View {
    let imageUrls: [String]
    @Binding var selectedImageIndex: Int?
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            Color.black.edgesIgnoringSafeArea(.all)
            
            if selectedImageIndex != nil {
                TabView {
                    ForEach(imageUrls.indices, id: \.self) { index in
                        AsyncImage(url: URL(string: imageUrls[index])) { phase in
                            switch phase {
                            case .empty:
                                ProgressView()
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                                    .onTapGesture {
                                        dismiss()
                                    }
                            case .failure:
                                Image(systemName: "photo")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                            @unknown default:
                                EmptyView()
                            }
                        }
                        .tag(index)
                    }
                }
                .tabViewStyle(PageTabViewStyle())
            }
            
            Button(action: {
                dismiss()
            }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.largeTitle)
                    .padding()
                    .foregroundColor(.white)
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(isLoading: .constant(false), userId: .constant("9FFPiZroJ2Nb9zneZer9NDleUpM2"), messagingService: MessagingService(), role: "Sitter")
            .environmentObject(AuthService())
            .environmentObject(UserProfileService(authService: AuthService()))
            .environmentObject(StorageService())
            .environmentObject(NavigationPathManager())
            .environmentObject(FirestoreService())
    }
}
