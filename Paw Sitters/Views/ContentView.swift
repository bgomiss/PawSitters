//
//  ContentView.swift
//  Paw Sitters
//
//  Created by aycan duskun on 21.06.2024.
//
//import SwiftUI
//import MapKit
//
//struct ContentView: View {
//    @Binding var isLoading: Bool
//    @Binding var userId: String
//    @State private var issLoading: Bool = false
//    @EnvironmentObject var authService: AuthService
//    @ObservedObject var firestoreService: FirestoreService
//    @EnvironmentObject var userProfileService: UserProfileService
//    @ObservedObject var messagingService: MessagingService
//    @EnvironmentObject var navigationPathManager: NavigationPathManager
//    @State private var listings: [PetSittingListing] = []
//    @State private var isFullScreenCoverPresented = false
//    @State private var isMapViewPresented = false
//    @State var selectedTab = 0
//    @ObservedObject var viewModel = MapViewModel()
//        @State private var region = MKCoordinateRegion(
//            center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
//            span: MKCoordinateSpan(latitudeDelta: 10, longitudeDelta: 10)
//        )
//    
//   // NavigationStack(path: $navigationPathManager.path) {
//    var role: String?
//  //  var tabView: AnyView?
//    
//    var body: some View {
//        TabView(selection: $selectedTab) {
//            NavigationStack(path: $navigationPathManager.path) {
//                ContentView(isLoading: $isLoading, userId: $userId, firestoreService: firestoreService, messagingService: messagingService)
//            }
//                    .tabItem {
//                        Image(systemName: "house")
//                        Text("Home")
//                    }
//                    .tag(0)
//            NavigationStack(path: $navigationPathManager.path) {
//                ConversationsView(messagingService: messagingService, userId: $userId)
//            }
//                    .tabItem {
//                        Image(systemName: "message")
//                        Text("Messages")
//                    }
//                    .tag(1)
//            NavigationStack(path: $navigationPathManager.path) {
//                ProfileView(role: role ?? "Sitter")
//            }
//                    .tabItem {
//                        Image(systemName: "person")
//                        Text("Profile")
//                    }
//                    .tag(2)
//            }
//        
//                VStack {
//                    Text("PAWSITTERS")
//                        .font(.headline)
//                        .padding(.top, -30)
//                        .frame(maxWidth: .infinity, alignment: .center)
//                        .fontWeight(.bold)
//                    if isLoading {
//                        Text("Loading listings...")
//                            .font(.headline)
//                            .padding()
//                    } else if firestoreService.listings.isEmpty {
//                        Text("No listings available.")
//                            .font(.headline)
//                            .padding()
//                    } else {
//                        ScrollView {
//                            ForEach(firestoreService.listings) { listing in
//                                NavigationLink(destination: ListingDetailView(listing: listing, userId: $userId, messagingService: messagingService)) {
//                                    VStack(alignment: .leading) {
//                                        
//                                        if let imageUrl = listing.imageUrls?.first, let url = URL(string: imageUrl) {
//                                            AsyncImage(url: url) { phase in
//                                                switch phase {
//                                                case .empty:
//                                                    ProgressView()
//                                                        .frame(maxWidth: .infinity, maxHeight: 200)
//                                                case .success(let image):
//                                                    image
//                                                        .resizable()
//                                                        .scaledToFill()
//                                                        .frame(maxWidth: .infinity, maxHeight: 200)
//                                                        .clipped()
//                                                case .failure:
//                                                    Image(systemName: "photo")
//                                                        .resizable()
//                                                        .scaledToFit()
//                                                        .frame(maxWidth: .infinity, maxHeight: 200)
//                                                @unknown default:
//                                                    EmptyView()
//                                                }
//                                            }
//                                            .cornerRadius(10)
//                                        }
//                                        Text(listing.title)
//                                            .font(.headline)
//                                            .padding([.top, .leading, .trailing])
//                                            .frame(maxWidth: .infinity, alignment: .leading)
//                                        
//                                        if let dateRange = listing.dateRange {
//                                            Text("Date: \(dateRange)")
//                                                .font(.headline)
//                                                .padding([.leading, .trailing])
//                                                .frame(maxWidth: .infinity, alignment: .leading)
//                                        } else {
//                                            Text("No Date selected")
//                                        }
//                                        
//                                        Text(listing.location ?? "")
//                                            .font(.headline)
//                                            .padding([.leading, .trailing])
//                                            .frame(maxWidth: .infinity, alignment: .leading)
//                                        HStack {
//                                            if let pet = listing.pets {  // Eğer pets dizisinde ilk öğe varsa
//                                                if let dogs = pet.numDogs {
//                                                    Image(systemName: "dog.fill")
//                                                    Text(dogs)
//                                                }
//                                                if let hares = pet.numHares {
//                                                    Image(systemName: "hare.fill")
//                                                    Text(hares)
//                                                }
//                                                if let birds = pet.numBirds {
//                                                    Image(systemName: "bird.fill")
//                                                    Text(birds)
//                                                }
//                                                if let others = pet.numOthers {
//                                                    Image(systemName: "pawprint.fill")
//                                                    Text(others)
//                                                }
//                                            }
//                                        }
//                                        .padding([.leading, .trailing])
//                                        .frame(maxWidth: .infinity, alignment: .leading)
//                                    }
//                                }
//                                .background(Rectangle().fill(Color.white).shadow(radius: 1))
//                                .cornerRadius(10)
//                                .padding(.vertical, 5)
//                                .padding(.horizontal, 15)
//                                
//                            }
//                          
//                        }
//                        // ZStack {
//                        Button(action: {
//                            let zoomLevel = region.span.latitudeDelta
//                            viewModel.createAnnotations(from: firestoreService.listings, zoomLevel: zoomLevel)
//                            isMapViewPresented.toggle()
//                        }, label: {
//                            Image(systemName: "map.fill")
//                                .padding()
//                                .background(Color.black)
//                                .foregroundColor(.white)
//                                .cornerRadius(8)
//                        })
//                        //}
//                     }
//                    
//               // tabView
//            }
//            .navigationBarItems(
//                leading: HStack {
//                    Image(systemName: "person.crop.circle")
//                        .onTapGesture {
//                            navigationPathManager.push(.profileView)
//                            print("Image tapped!")
//                        }
//                },
//                trailing: HStack {
//                    Image(systemName: "message")
//                        .onTapGesture {
//                            isFullScreenCoverPresented.toggle()
//                        }
//                }
//            )
//            .toolbar {
//                ToolbarItem(placement: .principal) {
//                    Button(action: {
//                        withAnimation(.snappy) {
//                            navigationPathManager.push(.createListingView)
//                        }
//                    }) {
//                        Text("Post Your Own Listing")
//                            .padding(.horizontal)
//                            .frame(height: 30)
//                            .background(Color.secondary)
//                            .foregroundColor(.white)
//                            .cornerRadius(8)
//                    }
//                }
//            }
//            .navigationDestination(for: NavigationDestination.self) { destination in
//                switch destination {
//                case .profileView:
//                    ProfileView(role: role ?? "Sitter")
//                case .conversationsView:
//                    ConversationsView(messagingService: messagingService, userId: $userId)
//                case .createListingView:
//                    CreateListingView(role: role)
//                default:
//                    Text("GuimelContentView")
//                }
//            }
//            .onAppear {
//                issLoading.toggle()
//                if let user = authService.user {
//                    userProfileService.fetchUserProfile(uid: user.uid) { result in
//                        switch result {
//                        case .success(let profile):
//                            DispatchQueue.main.async {
//                                userProfileService.userProfile = profile
//                                firestoreService.fetchListings(for: profile.role) // Use the role from the fetched profile
//                            }
//                        case .failure(let error):
//                            print("Error fetching user profile: \(error.localizedDescription)")
//                            isLoading = false
//                        }
//                    }
//                }
//            }
//            .fullScreenCover(isPresented: $isFullScreenCoverPresented) {
//                ConversationsView(messagingService: messagingService, userId: $userId)
//            }
//            .fullScreenCover(isPresented: $isMapViewPresented) {
//                MapContainerView(annotations: $viewModel.annotations, region: $region, listings: firestoreService.listings)
//            }
//        }
//    }

import SwiftUI
import MapKit

struct ContentView: View {
    @Binding var isLoading: Bool
    @Binding var userId: String
    @EnvironmentObject var authService: AuthService
    @ObservedObject var firestoreService: FirestoreService
    @StateObject private var imageCache = ImageCacheViewModel()
    @EnvironmentObject var userProfileService: UserProfileService
    @ObservedObject var messagingService: MessagingService
    @ObservedObject var storageService: StorageService
    @EnvironmentObject var navigationPathManager: NavigationPathManager
    @State private var listings: [PetSittingListing] = []
    @State private var isFullScreenCoverPresented = false
    @State private var isMapViewPresented = false
    @State var selectedTab = 0
    @ObservedObject var viewModel = MapViewModel()
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
        span: MKCoordinateSpan(latitudeDelta: 10, longitudeDelta: 10)
    )
    
    var role: String?

    var body: some View {
        GeometryReader { proxy in
                VStack {
                    Spacer()
                    HStack(alignment: .bottom) {
                        TabBarItem(label: "Listings", iconName: "house.fill") {}
                        TabBarItem(label: "Favorites", iconName: "heart.fill") {}
                        Text("Create")
                        TabBarItem(label: "Messages", iconName: "message.fill") {}
                        TabBarItem(label: "Profile", iconName: "person.fill") {}
                    }
                    .font(.footnote)
                    .padding(.top, 42)
                    .overlay(alignment: .top) {
                        Button {
                            print("Create Button Action")
                        } label: {
                            Image(systemName: "plus") // "plus_icon"
                                .resizable()
                                .scaledToFit()
                                .padding()
                                .frame(width: 50, height: 50)
                                .foregroundStyle(.white)
                                .background {
                                    Circle()
                                        .fill(.green) // custom64B054Color
                                        .shadow(radius: 3)
                                }
                        }
                        .padding(9)
                    }
                    .padding(.bottom, max(8, proxy.safeAreaInsets.bottom))
                    .background {
                        TabBarShape()
                            .fill(.white)
                            .shadow(radius: 3)
                    }
                }
                .ignoresSafeArea(edges: .bottom)
            }
        }
    
    
    
    // MARK: - TabView
    
//    private var tabView: some View {
//        ZStack {
//            TabView(selection: $selectedTab) {
//                homeView
//                    .environmentObject(imageCache)
//                    .tabItem {
//                        Image(systemName: "house")
//                        Text("Home")
//                    }
//                    .tag(0)
//
//                FavoritesView(userId: $userId, firestoreService: firestoreService, storageService: storageService, messagingService: messagingService, role: self.role)
//                    .tabItem {
//                        Image(systemName: "heart")
//                        Text("Favorites")
//                    }
//                    .tag(1)
//
//                ConversationsView(messagingService: messagingService, storageService: storageService, userId: $userId)
//                    .tabItem {
//                        Image(systemName: "message")
//                        Text("Messages")
//                    }
//                    .tag(2)
//
//                ProfileView(role: role ?? "Sitter")
//                    .tabItem {
//                        Image(systemName: "person")
//                        Text("Profile")
//                    }
//                    .tag(3)
//            }
//            
//            VStack {
//                Spacer()
//                
//                HStack {
//                    Spacer()
//                    
//                    Button(action: {
//                        CreateListingView(role: role)
//                    }) {
//                        VStack {
//                            ZStack {
//                                Circle()
//                                    .fill(Color.blue)
//                                    .frame(width: 40, height: 40)
//                                
//                                Image(systemName: "plus")
//                                    .foregroundColor(.white)
//                                    .font(.system(size: 24))
//                            }
//                            Text("Post")
//                                .foregroundColor(.black)
//                                .font(.footnote)
//                        }
//                    }
//                    .padding(.bottom, 10) // Adjust to make it look good in your layout
//                    
//                    Spacer()
//                }
//            }
//            .ignoresSafeArea(.keyboard, edges: .bottom) // Ensure it doesn't interfere with the keyboard
//        }
//    }


    
    // MARK: - HomeView
    private var homeView: some View {
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
                } else if firestoreService.listings.isEmpty {
                    Text("No listings available.")
                        .font(.headline)
                        .padding()
                } else {
                    ScrollView {
                        ForEach(firestoreService.listings) { listing in
                            NavigationLink(destination: ListingDetailView(listing: listing, userId: $userId, messagingService: messagingService, storageService: storageService)) {
                                ImagesView(listing: listing, role: self.role, firestoreService: firestoreService, imageCache: imageCache)
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
                            HStack {
                                Text(listing.location ?? "")
                                    .font(.subheadline)
                                    .fontWeight(.light)
                                    .foregroundColor(Color(white: 0.7))
                                    .padding([.leading])
                                    .frame(alignment: .leading)
                                ZStack {
                                    Image(systemName: "mappin.and.ellipse")
                                        .foregroundColor(.black)  // Çubuk için siyah
                                    Image(systemName: "circle.fill")
                                        .foregroundColor(Color(red: 0.7, green: 0, blue: 0.3))  // Üstteki yuvarlak için vişne rengi
                                        .offset(y: -10)  // Çubuğun üst kısmındaki yuvarlağı hizalıyoruz
                                        .scaleEffect(0.5)  // Yuvarlağı uygun boyuta getiriyoruz
                                }
                                Spacer()
                            }
                            HStack {
                                if let pet = listing.pets {
                                    if let dogsString = pet.numDogs, let dogs = Int(dogsString), dogs > 0  {
                                        Image(systemName: "dog.fill")
                                        Text(dogsString)
                                    }
                                    if let haresString = pet.numHares, let hares = Int(haresString), hares > 0  {
                                        Image(systemName: "hare.fill")
                                        Text(haresString)
                                    }
                                    if let birdsString = pet.numBirds, let birds = Int(birdsString), birds > 0  {
                                        Image(systemName: "bird.fill")
                                        Text(birdsString)
                                    }
                                    if let catsString = pet.numCats, let cats = Int(catsString), cats > 0  {
                                        Image(systemName: "bird.fill")
                                        Text(catsString)
                                    }
                                    if let othersString = pet.numOthers, let others = Int(othersString), others > 0  {
                                        Image(systemName: "pawprint.fill")
                                        Text(othersString)
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
                    .overlay(alignment: .bottom) {
                        Button(action: {
                            let zoomLevel = region.span.latitudeDelta
                            viewModel.createAnnotations(from: firestoreService.listings, zoomLevel: zoomLevel)
                            isMapViewPresented.toggle()
                        }, label: {
                            Image(systemName: "map.fill")
                                .padding()
                                .background(Color.black)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        })
                        .padding(.bottom, 10)
                    }
                }
            }
        }
//            .navigationBarItems(
//                leading: HStack {
//                    Image(systemName: "person.crop.circle")
//                        .onTapGesture {
//                            navigationPathManager.push(.profileView)
//                            print("Image tapped!")
//                        }
//                },
//                trailing: HStack {
//                    Image(systemName: "message")
//                        .onTapGesture {
//                            isFullScreenCoverPresented.toggle()
//                        }
//                }
//            )
//            .toolbar {
//                ToolbarItem(placement: .principal) {
//                    Button(action: {
//                        withAnimation(.snappy) {
//                            navigationPathManager.push(.createListingView)
//                        }
//                    }) {
//                        Text("Post Your Own Listing")
//                            .padding(.horizontal)
//                            .frame(height: 30)
//                            .background(Color.secondary)
//                            .foregroundColor(.white)
//                            .cornerRadius(8)
//                    }
//                }
//
//            .navigationDestination(for: NavigationDestination.self) { destination in
//                switch destination {
//                case .profileView:
//                    ProfileView(role: role ?? "Sitter")
//                case .conversationsView:
//                    ConversationsView(messagingService: messagingService, storageService: storageService, userId: $userId)
//                case .createListingView:
//                    CreateListingView(role: role)
//                default:
//                    Text("GuimelContentView")
//                }
//            }
            .onAppear {
                if let user = authService.user {
                    userProfileService.fetchUserProfile(uid: user.uid) { result in
                        switch result {
                        case .success(let profile):
                            DispatchQueue.main.async {
                                userProfileService.userProfile = profile
                                firestoreService.fetchListings(for: profile.role)
                            }
                        case .failure(let error):
                            print("Error fetching user profile: \(error.localizedDescription)")
                            isLoading = false
                        }
                    }
                }
            }
            
            
            .fullScreenCover(isPresented: $isFullScreenCoverPresented) {
                ConversationsView(messagingService: messagingService, storageService: storageService, userId: $userId)
            }
            .fullScreenCover(isPresented: $isMapViewPresented) {
                MapContainerView(annotations: $viewModel.annotations, region: $region, firestoreService: firestoreService, listings: firestoreService.listings)
            }
        }
}

struct ListingDetailView: View {
    var listing: PetSittingListing
    @Binding var userId: String
    @ObservedObject var messagingService: MessagingService
    @ObservedObject var storageService: StorageService
    @EnvironmentObject var authService: AuthService
    @State private var selectedImageIndex: Int? = nil
    @State private var showingImageDetail = false
    @State private var isMessagingViewPresented = false

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
                Text("Date: \(dateRange)")
                    .padding()
            } else {
                Text("No Date selected")
            }
            
            Button(action: {
                    isMessagingViewPresented.toggle()
                }, label: {
                    Text("Apply")
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                })
            }
        .fullScreenCover(isPresented: $isMessagingViewPresented) {
            MessagingView(messagingService: messagingService, storageService: storageService, userId: $userId, receiverId: listing.ownerId)
        }
            .padding(.top, 10)
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
        ContentView(
            isLoading: .constant(false),
            userId: .constant("49WVp3v9rjMtZr4wYmD6A1yfDKc2"),
            firestoreService: FirestoreService(),
            messagingService: MessagingService(),
            storageService: StorageService(), role: "Sitter"
        )
        .environmentObject(AuthService())
        .environmentObject(UserProfileService(authService: AuthService()))
        .environmentObject(StorageService())
        .environmentObject(NavigationPathManager())
        .environmentObject(FirestoreService())
        .environmentObject(ImageCacheViewModel())  // Include the ImageCacheViewModel
    }
}
