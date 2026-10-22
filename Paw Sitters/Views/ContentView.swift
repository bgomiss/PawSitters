//
//  ContentView.swift
//  Paw Sitters
//
//  Created by aycan duskun on 21.06.2024.

import SwiftUI
import MapKit

struct ContentView: View {
    @Binding var isLoading: Bool
    @State var userId: String
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var firestoreService: FirestoreService
    @StateObject private var imageCache = ImageCacheViewModel()
    @EnvironmentObject var userProfileService: UserProfileService
    @EnvironmentObject var messagingService: MessagingService
    @EnvironmentObject var storageService: StorageService
    @EnvironmentObject var navigationPathManager: NavigationPathManager
    @EnvironmentObject var applicationService: ApplicationService
    @EnvironmentObject var reviewService: ReviewService
    @EnvironmentObject var moderationService: ModerationService
    @State private var listings: [PetSittingListing] = []
    @State private var isFullScreenCoverPresented = false
    @State private var filters = ListingFilters()
    @State private var isFilterSheetPresented = false
    @State private var isMapViewPresented = false
    @ObservedObject var mapViewModel = MapViewModel()
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
        span: MKCoordinateSpan(latitudeDelta: 10, longitudeDelta: 10)
    )
    @State private var selectedTab: Tab = .listings
    @State private var selectedListingId: String?
    enum Tab: Hashable {
        case listings, favorites, create, messages, profile
    }
    
    var role: String?
    
    var body: some View {
        NavigationStack {
            tabView
                .pawBackground()
                .toolbar(.hidden, for: .navigationBar)
                .ignoresSafeArea(edges: .bottom)
                .sheet(isPresented: $isFilterSheetPresented) {
                    ListingFilterSheet(filters: $filters, listings: firestoreService.listings)
                        .presentationDetents([.medium, .large])
                        .presentationDragIndicator(.visible)
                }
        }
    }
    
    /// Listings after applying the filters chosen in the filter sheet.
    private var visibleListings: [PetSittingListing] {
        firestoreService.listings.filter { filters.matches($0) && !moderationService.isBlocked($0.ownerId) }
    }
    
    private var safeAreaBottomInset: CGFloat {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?
            .windows
            .first?
            .safeAreaInsets.bottom ?? 8
    }
    

    // MARK: - TabView
    private var tabView: some View {
        VStack {
            // Dinamik olarak görünüm seçimi
            switch selectedTab {
            case .listings:
                homeView
            case .favorites:
                FavoritesView(userId: $userId)
            case .create:
                CreateListingView(role: role) {
                    selectedTab = .listings
                }
            case .messages:
                MessagesHubView(userId: $userId)
            case .profile:
                ProfileView(role: role ?? "Sitter")
            }
            
            Spacer()
            
            // Alt tab bar
            HStack {
                TabBarItem(label: "Listings", iconName: "house.fill", isSelected: selectedTab == .listings, action: {
                    selectedTab = .listings
                })
                TabBarItem(label: "Favorites", iconName: "heart.fill", isSelected: selectedTab == .favorites, action: {
                    selectedTab = .favorites
                })
                Text("Create")
                    .foregroundStyle(selectedTab == .create ? AppTheme.current.primary : .gray)
                
                TabBarItem(label: "Messages", iconName: "message.fill", isSelected: selectedTab == .messages,
                           badge: applicationService.pendingReceivedCount, action: {
                    selectedTab = .messages
                })
                TabBarItem(label: "Profile", iconName: "person.fill", isSelected: selectedTab == .profile, action: {
                    selectedTab = .profile
                })
            }
            .font(.footnote)
            .padding(.top, 42)
            .overlay(alignment: .top) {
                Button {
                    selectedTab = .create
                } label: {
                    Image(systemName: "plus") // "plus_icon"
                        .resizable()
                        .scaledToFit()
                        .padding()
                        .frame(width: 50, height: 50)
                        .foregroundStyle(.white)
                        .background {
                            Circle()
                                .fill(AppTheme.current.accent)
                                .shadow(radius: 3)
                        }
                }
                .padding(9)
            }
            .padding(.bottom, max(8, safeAreaBottomInset))
            .background {
                TabBarShape()
                    .fill(Color.white)
                    .shadow(radius: 3)
            }
        }
    }

    
    // MARK: - HomeView
    private var homeView: some View {
       // NavigationStack(path: $navigationPathManager.path) {
            VStack {
                HStack {
                    Label("Paw Sitters", systemImage: "pawprint.fill")
                        .font(.system(.title2, design: .rounded).weight(.bold))
                        .foregroundStyle(AppTheme.current.text)
                        .labelStyle(AccentIconLabelStyle())
                    Spacer()
                    FilterButton(activeCount: filters.activeCount) {
                        isFilterSheetPresented = true
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                
                if !filters.isEmpty {
                    ActiveFilterChips(filters: $filters)
                        .transition(.opacity)
                }
                
                if isLoading {
                    Spacer()
                    ProgressView("Loading listings…")
                        .tint(AppTheme.current.primary)
                    Spacer()
                } else if firestoreService.listings.isEmpty {
                    EmptyStateView(icon: "dog.fill",
                                   title: "No listings yet",
                                   message: role == "Sitter"
                                       ? "When owners post a pet-sitting request, it'll show up here."
                                       : "When sitters offer their help, they'll show up here.")
                } else if visibleListings.isEmpty && filters.isEmpty {
                    // Everything left is from people the user blocked.
                    EmptyStateView(icon: "dog.fill",
                                   title: "No listings yet",
                                   message: role == "Sitter"
                                       ? "When owners post a pet-sitting request, it'll show up here."
                                       : "When sitters offer their help, they'll show up here.")
                } else if visibleListings.isEmpty {
                    VStack(spacing: 16) {
                        EmptyStateView(icon: "magnifyingglass",
                                       title: "No matches",
                                       message: "No listings match these filters. Try a different city, dates or environment.")
                        Button("Clear filters") {
                            withAnimation(.snappy) { filters = ListingFilters() }
                        }
                        .font(.system(.headline, design: .rounded))
                        .foregroundStyle(AppTheme.current.accent)
                        Spacer()
                    }
                } else {
                    ScrollView {
                        ForEach(visibleListings) { listing in
                            VStack {
                                ImagesView(listing: listing, role: self.role, imageCache: imageCache)
                                HStack(alignment: .firstTextBaseline) {
                                    Text(listing.title)
                                        .font(.system(.headline, design: .rounded))
                                        .foregroundStyle(AppTheme.current.text)
                                    Spacer()
                                    RatingBadge(summary: reviewService.summary(for: listing.ownerId))
                                        .font(.caption)
                                        .onAppear { reviewService.loadReviews(for: listing.ownerId) }
                                }
                                .padding([.top, .leading, .trailing], 4)
                                
                                Label {
                                    if let dateRange = listing.dateRange {
                                        Text("\(dateRange.lowerBound.formatted(date: .abbreviated, time: .omitted)) – \(dateRange.upperBound.formatted(date: .abbreviated, time: .omitted))")
                                    } else {
                                        Text("Flexible dates")
                                    }
                                } icon: {
                                    Image(systemName: "calendar")
                                        .foregroundStyle(AppTheme.current.primary)
                                }
                                .font(.system(.subheadline, design: .rounded))
                                .foregroundStyle(AppTheme.current.text.opacity(0.75))
                                .padding(.horizontal, 4)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                if let location = listing.location, !location.isEmpty {
                                    Label {
                                        Text(location)
                                    } icon: {
                                        Image(systemName: "mappin.and.ellipse")
                                            .foregroundStyle(AppTheme.current.accent)
                                    }
                                    .font(.system(.subheadline, design: .rounded))
                                    .foregroundStyle(AppTheme.current.text.opacity(0.75))
                                    .padding(.horizontal, 4)
                                    .frame(maxWidth: .infinity, alignment: .leading)
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
                                            Image(systemName: "cat.fill")
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
                            // The whole card opens the listing (the favorite button keeps its own tap).
                            .contentShape(Rectangle())
                            .onTapGesture { selectedListingId = listing.documentId }
                            .modifier(CollapsibleDestinationViewModifier())
                            }
                        }
                    
                        // Native pull-to-refresh (the old custom RefreshControl kept firing in a loop).
                        .refreshable {
                            await firestoreService.refreshListings()
                        }
                        .overlay(alignment: .bottom) {
                            Button(action: {
                                let zoomLevel = region.span.latitudeDelta
                                mapViewModel.createAnnotations(from: visibleListings, zoomLevel: zoomLevel)
                                isMapViewPresented.toggle()
                            }, label: {
                                Label("Map", systemImage: "map.fill")
                                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
                                    .padding(.horizontal, 18)
                                    .padding(.vertical, 12)
                                    .background(AppTheme.current.text, in: Capsule())
                                    .foregroundColor(.white)
                                    .shadow(color: .black.opacity(0.2), radius: 6, y: 3)
                            })
                            .padding(.bottom, 10)
                        }
                    }
                }
            .onAppear {
                if let user = authService.user {
                    userProfileService.fetchUserProfile(uid: user.uid) { result in
                        switch result {
                        case .success(let profile):
                            DispatchQueue.main.async {
                                userProfileService.userProfile = profile
                                firestoreService.fetchListings(for: profile.role)
                                firestoreService.listenToFavorites()
                                applicationService.startListening()
                                moderationService.startListening()
                                reviewService.startListening()
                                PushNotifications.registerForSignedInUser()
                            }
                        case .failure(let error):
                            print("Error fetching user profile: \(error.localizedDescription)")
                            isLoading = false
                        }
                    }
                }
            }
            
            
            
            .navigationDestination(item: $selectedListingId) { listingId in
                if let listing = firestoreService.listings.first(where: { $0.documentId == listingId }) {
                    ListingDetailView(listing: listing, userId: userId)
                }
            }
            .fullScreenCover(isPresented: $isMapViewPresented) {
                MapContainerView(annotations: $mapViewModel.annotations, region: $region, listings: visibleListings)
            }
        }
    }



struct ListingDetailView: View {
    var listing: PetSittingListing
    @State var userId: String
    @EnvironmentObject var messagingService: MessagingService
    @EnvironmentObject var storageService: StorageService
    @EnvironmentObject var userProfileService: UserProfileService
    @EnvironmentObject var authService: AuthService
    @State private var selectedImageIndex: Int? = nil
    @State private var showingImageDetail = false
    @State private var isMessagingViewPresented = false
    @State private var isApplySheetPresented = false
    @EnvironmentObject var applicationService: ApplicationService

    private let theme = AppTheme.current
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                if let imageUrls = listing.imageUrls?.filter({ !$0.isEmpty }), !imageUrls.isEmpty {
                    TabView {
                        ForEach(imageUrls.indices, id: \.self) { index in
                            AsyncImage(url: URL(string: imageUrls[index])) { phase in
                                switch phase {
                                case .empty:
                                    ProgressView()
                                case .success(let image):
                                    image
                                        .resizable()
                                        .scaledToFill()
                                        .frame(maxWidth: .infinity, maxHeight: 300)
                                        .clipped()
                                        .onTapGesture {
                                            self.selectedImageIndex = index
                                            self.showingImageDetail = true
                                        }
                                case .failure:
                                    Image(systemName: "photo")
                                        .font(.largeTitle)
                                        .foregroundStyle(theme.primary)
                                @unknown default:
                                    EmptyView()
                                }
                            }
                            .tag(index)
                        }
                    }
                    .frame(height: 300)
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .tabViewStyle(PageTabViewStyle())
                    .fullScreenCover(isPresented: $showingImageDetail) {
                        ImageDetailView(imageUrls: imageUrls, selectedImageIndex: $selectedImageIndex)
                    }
                } else {
                    Image(systemName: "dog.fill")
                        .font(.system(size: 64))
                        .foregroundStyle(theme.primary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 200)
                        .background(theme.secondary.opacity(0.45), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                }
                
                VStack(alignment: .leading, spacing: 12) {
                    Text(listing.title)
                        .font(.system(.title, design: .rounded).weight(.bold))
                        .foregroundStyle(theme.text)
                    
                    if !listing.name.isEmpty {
                        HStack(spacing: 8) {
                            detailRow(icon: "person.crop.circle.fill", text: listing.name)
                            if userProfileService.cachedProfile(uid: listing.ownerId)?.emailVerified == true {
                                VerifiedBadge()
                            }
                        }
                    }
                    if let location = listing.location, !location.isEmpty {
                        detailRow(icon: "mappin.and.ellipse", text: location)
                    }
                    if let dateRange = listing.dateRange {
                        detailRow(icon: "calendar",
                                  text: "\(dateRange.lowerBound.formatted(date: .abbreviated, time: .omitted)) – \(dateRange.upperBound.formatted(date: .abbreviated, time: .omitted))")
                    } else {
                        detailRow(icon: "calendar", text: "Flexible dates")
                    }
                    if !listing.environment.isEmpty {
                        detailRow(icon: "leaf.fill", text: listing.environment)
                    }
                    
                    if !listing.description.isEmpty {
                        Divider()
                        Text(listing.description)
                            .font(.system(.body, design: .rounded))
                            .foregroundStyle(theme.text.opacity(0.85))
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(18)
                .themedCard()
                
                applicationSection
                    .padding(.top, 4)
                
                if listing.ownerId != userId && !listing.ownerId.isEmpty {
                    ReviewsSection(userId: listing.ownerId,
                                   title: listing.name.isEmpty ? "Reviews" : "Reviews of \(listing.name)",
                                   limit: 3)
                }
            }
            .padding()
        }
        .pawBackground()
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if listing.ownerId != userId {
                ToolbarItem(placement: .topBarTrailing) {
                    ModerationMenu(target: .listing(listing))
                }
            }
        }
        .fullScreenCover(isPresented: $isMessagingViewPresented) {
            MessagingView(userId: userId, receiverId: listing.ownerId)
        }
        .sheet(isPresented: $isApplySheetPresented) {
            ApplySheet(listing: listing)
        }
    }
    
    @ViewBuilder
    private var applicationSection: some View {
        if listing.ownerId == userId {
            // Your own listing: show how many people applied instead of an Apply button.
            let count = applicationService.received.filter { $0.listingId == listing.documentId && $0.status == .pending }.count
            Label(count == 0 ? "No pending applications yet" : "\(count) pending application\(count == 1 ? "" : "s") – see Messages › Applications",
                  systemImage: "tray.full.fill")
                .font(.system(.subheadline, design: .rounded).weight(.semibold))
                .foregroundStyle(theme.text.opacity(0.75))
        } else if let application = applicationService.application(for: listing),
                  application.status != .withdrawn {
            VStack(spacing: 12) {
                HStack {
                    Text("Your application")
                        .font(.system(.headline, design: .rounded))
                        .foregroundStyle(theme.text)
                    Spacer()
                    StatusBadge(status: application.status)
                }
                Button {
                    isMessagingViewPresented = true
                } label: {
                    Label("Message \(listing.name.isEmpty ? "owner" : listing.name)", systemImage: "bubble.left.fill")
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                        .themedButton(theme.accent)
                }
            }
            .padding(16)
            .themedCard()
        } else {
            Button {
                isApplySheetPresented = true
            } label: {
                Label("Apply", systemImage: "paperplane.fill")
                    .themedButton()
            }
        }
    }
    
    private func detailRow(icon: String, text: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .foregroundStyle(theme.primary)
                .frame(width: 22)
            Text(text)
                .font(.system(.subheadline, design: .rounded))
                .foregroundStyle(theme.text)
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
        ContentView(
            isLoading: .constant(false),
            userId: "49WVp3v9rjMtZr4wYmD6A1yfDKc2",
            role: "Sitter"
        )
        .environmentObject(AuthService())
        .environmentObject(UserProfileService(authService: AuthService()))
        .environmentObject(StorageService())
        .environmentObject(NavigationPathManager())
        .environmentObject(FirestoreService())
        .environmentObject(ImageCacheViewModel())  // Include the ImageCacheViewModel
    }
}

struct RefreshControl: View {
    let coordinateSpace: CoordinateSpace
    let onRefresh: () async -> Void
    @State private var isRefreshing = false
    
    var body: some View {
        GeometryReader { geo in
            if geo.frame(in: coordinateSpace).midY > 50 {
                Spacer()
                    .onAppear {
                        guard !isRefreshing else { return }
                        isRefreshing = true
                        Task {
                            await onRefresh()
                            isRefreshing = false
                        }
                    }
            }
            HStack {
                Spacer()
                if isRefreshing {
                    ProgressView()
                }
                Spacer()
            }
        }.padding(.top, -50)
    }
}

