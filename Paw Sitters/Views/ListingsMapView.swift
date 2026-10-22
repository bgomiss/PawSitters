//
//  ListingsMapView.swift
//  Paw Sitters
//
//  Airbnb-style map of listings: nearby listings merge into a bubble showing
//  how many there are, zooming in splits them into individual paw markers,
//  and tapping a marker shows its listing card at the bottom.
//

import MapKit
import SwiftUI

// MARK: - Coordinates

/// Looks up coordinates for listings that only have a city name, and caches them.
@MainActor
final class ListingLocator: ObservableObject {
    static let shared = ListingLocator()
    @Published private(set) var cityCoordinates: [String: CLLocationCoordinate2D] = [:]
    private var pending: Set<String> = []

    /// The listing's coordinate, or nil while its city is still being looked up.
    func coordinate(for listing: PetSittingListing) -> CLLocationCoordinate2D? {
        if let latitude = listing.latitude, let longitude = listing.longitude {
            return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        }
        guard let city = listing.location?.trimmingCharacters(in: .whitespacesAndNewlines), !city.isEmpty,
              let center = cityCoordinates[city] else { return nil }
        return Self.approximate(center, seed: listing.documentId)
    }

    func locate(_ listings: [PetSittingListing]) {
        for listing in listings where listing.latitude == nil || listing.longitude == nil {
            guard let city = listing.location?.trimmingCharacters(in: .whitespacesAndNewlines), !city.isEmpty,
                  cityCoordinates[city] == nil, !pending.contains(city) else { continue }
            pending.insert(city)
            let request = MKLocalSearch.Request()
            request.naturalLanguageQuery = city
            request.resultTypes = .address
            MKLocalSearch(request: request).start { [weak self] response, _ in
                Task { @MainActor in
                    self?.pending.remove(city)
                    if let coordinate = response?.mapItems.first?.placemark.coordinate {
                        self?.cityCoordinates[city] = coordinate
                    }
                }
            }
        }
    }

    /// Spreads listings that share a city around its centre (up to ~2 km), so they
    /// don't sit on one point and the exact home location isn't implied.
    private static func approximate(_ center: CLLocationCoordinate2D, seed: String) -> CLLocationCoordinate2D {
        var hash: UInt64 = 1469598103934665603
        for byte in seed.utf8 { hash = (hash ^ UInt64(byte)) &* 1099511628211 }
        let angle = Double(hash % 360) * .pi / 180
        let distance = 0.004 + Double((hash >> 16) % 1000) / 1000 * 0.014
        return CLLocationCoordinate2D(latitude: center.latitude + distance * sin(angle),
                                      longitude: center.longitude + distance * cos(angle) / max(cos(center.latitude * .pi / 180), 0.2))
    }
}

final class ListingAnnotation: NSObject, MKAnnotation {
    let listing: PetSittingListing
    @objc dynamic var coordinate: CLLocationCoordinate2D

    init(listing: PetSittingListing, coordinate: CLLocationCoordinate2D) {
        self.listing = listing
        self.coordinate = coordinate
    }

    var title: String? { listing.title }
}

// MARK: - Map screen

struct ListingsMapView: View {
    let listings: [PetSittingListing]
    let userId: String
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var locator = ListingLocator.shared
    /// Listings shown in the bottom card strip (one marker, or a cluster that can't split further).
    @State private var selected: [PetSittingListing] = []
    @State private var selectedId: String?
    /// ID of the listing whose card was tapped (pushed as the detail screen).
    @State private var openedListingId: String?
    private let theme = AppTheme.current

    private var annotations: [ListingAnnotation] {
        (listings + Self.demoListings).compactMap { listing in
            locator.coordinate(for: listing).map { ListingAnnotation(listing: listing, coordinate: $0) }
        }
    }

    /// Debug only: `-mapDemoListings N` adds N in-memory listings around a few
    /// cities to try clustering without real data. Never written to Firestore.
    private static let demoListings: [PetSittingListing] = {
        #if DEBUG
        let count = UserDefaults.standard.integer(forKey: "mapDemoListings")
        let cities: [(String, Double, Double)] = [("London", 51.507, -0.128), ("Istanbul", 41.008, 28.978),
                                                  ("Izmir", 38.423, 27.143), ("Manchester", 53.481, -2.242),
                                                  ("Antalya", 36.897, 30.713)]
        return (0..<count).map { index in
            let city = cities[index % cities.count]
            let spread = Double((index * 7919) % 100) / 100 - 0.5
            let spread2 = Double((index * 104729) % 100) / 100 - 0.5
            return PetSittingListing(documentId: "demo-\(index)", data: [
                "title": "Demo listing \(index + 1)",
                "location": city.0,
                "latitude": city.1 + spread * 0.3,
                "longitude": city.2 + spread2 * 0.4,
                "ownerId": "demo"
            ])
        }
        #else
        return []
        #endif
    }()
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                ClusteredListingsMap(annotations: annotations, selectedId: selectedId) { listings in
                    withAnimation(.snappy) {
                        selected = listings
                        selectedId = listings.count == 1 ? listings.first?.documentId : nil
                    }
                }
                .ignoresSafeArea()

                topBar

                VStack {
                    Spacer()
                    if selected.isEmpty {
                        listButton
                            .padding(.bottom, 28)
                            .transition(.opacity)
                    } else {
                        cardStrip
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
            }
            .navigationDestination(item: $openedListingId) { listingId in
                if let listing = (listings + Self.demoListings).first(where: { $0.documentId == listingId }) {
                    ListingDetailView(listing: listing, userId: userId)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .onAppear { locator.locate(listings) }
        }
    }

    private var topBar: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(theme.text)
                    .frame(width: 42, height: 42)
                    .background(.white, in: Circle())
                    .shadow(color: .black.opacity(0.15), radius: 6, y: 2)
            }
            .accessibilityLabel("Close map")
            Spacer()
            Label(annotations.count == 1 ? "1 listing" : "\(annotations.count) listings", systemImage: "pawprint.fill")
                .font(.system(.subheadline, design: .rounded).weight(.semibold))
                .foregroundStyle(theme.text)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(.white, in: Capsule())
                .shadow(color: .black.opacity(0.15), radius: 6, y: 2)
            Spacer()
            Color.clear.frame(width: 42, height: 42)
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }

    /// Mirror of the feed's "Map" button: switches back to the list.
    private var listButton: some View {
        Button {
            dismiss()
        } label: {
            Label("List", systemImage: "list.bullet")
                .font(.system(.subheadline, design: .rounded).weight(.semibold))
                .padding(.horizontal, 18)
                .padding(.vertical, 12)
                .background(theme.text, in: Capsule())
                .foregroundColor(.white)
                .shadow(color: .black.opacity(0.2), radius: 6, y: 3)
        }
        .accessibilityLabel("Show list")
    }
    
    private var cardStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: 12) {
                ForEach(selected) { listing in
                    MapListingCard(listing: listing) {
                        selectedId = nil
                        withAnimation(.snappy) { selected = [] }
                    }
                    .containerRelativeFrame(.horizontal) { width, _ in
                        selected.count == 1 ? width - 32 : width - 64
                    }
                    .onTapGesture { openedListingId = listing.documentId }
                }
            }
            .scrollTargetLayout()
            .padding(.horizontal, 16)
        }
        .scrollTargetBehavior(.viewAligned)
        .frame(height: 132)
        .padding(.bottom, 24)
    }
}

/// Compact listing card shown over the map.
struct MapListingCard: View {
    let listing: PetSittingListing
    var onClose: () -> Void
    @EnvironmentObject var reviewService: ReviewService
    @StateObject private var imageCache = ImageCacheViewModel()
    private let theme = AppTheme.current

    var body: some View {
        HStack(spacing: 12) {
            thumbnail
                .frame(width: 112, height: 112)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

            VStack(alignment: .leading, spacing: 5) {
                Text(listing.title)
                    .font(.system(.headline, design: .rounded))
                    .foregroundStyle(theme.text)
                    .lineLimit(2)
                    .padding(.trailing, 22) // room for the close button
                    .fixedSize(horizontal: false, vertical: true)
                if let location = listing.location, !location.isEmpty {
                    Label(ListingFilters.city(from: location), systemImage: "mappin.and.ellipse")
                        .lineLimit(1)
                }
                Label {
                    if let range = listing.dateRange {
                        Text("\(range.lowerBound.formatted(.dateTime.day().month(.abbreviated))) – \(range.upperBound.formatted(.dateTime.day().month(.abbreviated)))")
                    } else {
                        Text("Flexible dates")
                    }
                } icon: {
                    Image(systemName: "calendar")
                }
                Spacer(minLength: 0)
                RatingBadge(summary: reviewService.summary(for: listing.ownerId))
                    .font(.caption)
            }
            .font(.system(.caption, design: .rounded))
            .foregroundStyle(theme.text.opacity(0.7))
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 4)
        }
        .padding(10)
        .background(.white, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(alignment: .topTrailing) {
            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(theme.text.opacity(0.6))
                    .frame(width: 24, height: 24)
                    .background(theme.background, in: Circle())
            }
            .padding(8)
            .accessibilityLabel("Close")
        }
        .shadow(color: .black.opacity(0.18), radius: 10, y: 4)
        .contentShape(Rectangle())
        .onAppear { reviewService.loadReviews(for: listing.ownerId) }
    }

    @ViewBuilder
    private var thumbnail: some View {
        if let url = listing.imageUrl {
            if let image = imageCache.images[url] {
                Image(uiImage: image).resizable().scaledToFill()
            } else {
                theme.secondary.opacity(0.35)
                    .overlay(ProgressView().tint(theme.primary))
                    .onAppear { imageCache.loadImage(from: url) }
            }
        } else {
            theme.secondary.opacity(0.35)
                .overlay(Image(systemName: "pawprint.fill").font(.title).foregroundStyle(theme.primary.opacity(0.5)))
        }
    }
}

// MARK: - MapKit bridge

struct ClusteredListingsMap: UIViewRepresentable {
    let annotations: [ListingAnnotation]
    let selectedId: String?
    var onSelect: ([PetSittingListing]) -> Void

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.pointOfInterestFilter = .excludingAll
        mapView.showsCompass = false
        mapView.isRotateEnabled = false
        mapView.isPitchEnabled = false
        mapView.register(ListingMarkerView.self, forAnnotationViewWithReuseIdentifier: ListingMarkerView.reuseId)
        mapView.register(ListingClusterView.self,
                         forAnnotationViewWithReuseIdentifier: MKMapViewDefaultClusterAnnotationViewReuseIdentifier)
        let tap = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.mapTapped(_:)))
        tap.delegate = context.coordinator
        mapView.addGestureRecognizer(tap)
        return mapView
    }

    func updateUIView(_ mapView: MKMapView, context: Context) {
        context.coordinator.parent = self
        let current = mapView.annotations.compactMap { $0 as? ListingAnnotation }
        let currentIds = Set(current.map(\.listing.documentId))
        let newIds = Set(annotations.map(\.listing.documentId))
        if currentIds != newIds {
            mapView.removeAnnotations(current)
            mapView.addAnnotations(annotations)
            if !context.coordinator.didFitInitially, !annotations.isEmpty {
                context.coordinator.didFitInitially = true
                fit(mapView, to: annotations, animated: false)
            }
        }
        // Refresh marker styles so the selected one stands out.
        for annotation in mapView.annotations {
            (mapView.view(for: annotation) as? ListingMarkerView)?.isSelectedListing = (annotation as? ListingAnnotation)?.listing.documentId == selectedId
        }
    }

    /// Smallest span (in degrees, roughly 2 km) the map zooms to, so it never
    /// ends up on blank, fully zoomed-in tiles.
    fileprivate static let minimumSpan = 0.02
    
    fileprivate func fit(_ mapView: MKMapView, to annotations: [MKAnnotation], animated: Bool) {
        guard !annotations.isEmpty else { return }
        let latitudes = annotations.map(\.coordinate.latitude)
        let longitudes = annotations.map(\.coordinate.longitude)
        let center = CLLocationCoordinate2D(latitude: (latitudes.min()! + latitudes.max()!) / 2,
                                            longitude: (longitudes.min()! + longitudes.max()!) / 2)
        // 1.6× padding keeps markers clear of the top bar and the card strip.
        let span = MKCoordinateSpan(latitudeDelta: max((latitudes.max()! - latitudes.min()!) * 1.6, Self.minimumSpan * 4),
                                    longitudeDelta: max((longitudes.max()! - longitudes.min()!) * 1.6, Self.minimumSpan * 4))
        mapView.setRegion(mapView.regionThatFits(MKCoordinateRegion(center: center, span: span)), animated: animated)
    }

    final class Coordinator: NSObject, MKMapViewDelegate, UIGestureRecognizerDelegate {
        var parent: ClusteredListingsMap
        var didFitInitially = false

        init(_ parent: ClusteredListingsMap) {
            self.parent = parent
        }

        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            if annotation is MKClusterAnnotation {
                return mapView.dequeueReusableAnnotationView(withIdentifier: MKMapViewDefaultClusterAnnotationViewReuseIdentifier,
                                                             for: annotation)
            }
            guard let listing = annotation as? ListingAnnotation else { return nil }
            let view = mapView.dequeueReusableAnnotationView(withIdentifier: ListingMarkerView.reuseId, for: listing)
            (view as? ListingMarkerView)?.isSelectedListing = listing.listing.documentId == parent.selectedId
            return view
        }

        func mapView(_ mapView: MKMapView, didSelect annotation: MKAnnotation) {
            mapView.deselectAnnotation(annotation, animated: false)
            if let cluster = annotation as? MKClusterAnnotation {
                let members = cluster.memberAnnotations.compactMap { $0 as? ListingAnnotation }
                let latitudes = members.map(\.coordinate.latitude)
                let longitudes = members.map(\.coordinate.longitude)
                let membersSpan = max((latitudes.max() ?? 0) - (latitudes.min() ?? 0),
                                      (longitudes.max() ?? 0) - (longitudes.min() ?? 0))
                // Zoom into the cluster; if it's already close-up (or its listings share
                // almost the same spot), show their cards instead.
                if mapView.region.span.latitudeDelta < ClusteredListingsMap.minimumSpan * 5
                    || membersSpan < ClusteredListingsMap.minimumSpan / 4 {
                    parent.onSelect(members.map(\.listing))
                } else {
                    parent.onSelect([])
                    parent.fit(mapView, to: members, animated: true)
                }
            } else if let listing = annotation as? ListingAnnotation {
                parent.onSelect([listing.listing])
                mapView.setCenter(listing.coordinate, animated: true)
            }
        }

        /// Tapping empty map closes the card strip.
        @objc func mapTapped(_ gesture: UITapGestureRecognizer) {
            guard let mapView = gesture.view as? MKMapView else { return }
            let point = gesture.location(in: mapView)
            let hitAnnotation = mapView.annotations.contains { annotation in
                guard let view = mapView.view(for: annotation) else { return false }
                return view.frame.insetBy(dx: -8, dy: -8).contains(point)
            }
            if !hitAnnotation { parent.onSelect([]) }
        }

        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                               shouldRecognizeSimultaneouslyWith other: UIGestureRecognizer) -> Bool { true }
    }
}

// MARK: - Marker views

/// Single listing: white pill with a paw (green when selected), Airbnb-style.
final class ListingMarkerView: MKAnnotationView {
    static let reuseId = "ListingMarker"
    private let label = UILabel()

    /// Whether this marker's listing is the one shown in the card strip.
    var isSelectedListing = false {
        didSet { if oldValue != isSelectedListing { applyStyle() } }
    }

    // MapKit only clusters views whose identifier is set as the annotation is assigned.
    override var annotation: MKAnnotation? {
        willSet { clusteringIdentifier = "listing" }
    }

    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        clusteringIdentifier = "listing"
        displayPriority = .defaultHigh
        frame = CGRect(x: 0, y: 0, width: 40, height: 28)
        centerOffset = CGPoint(x: 0, y: -14)
        layer.cornerRadius = 14
        layer.borderWidth = 1
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.2
        layer.shadowRadius = 4
        layer.shadowOffset = CGSize(width: 0, height: 2)
        label.frame = bounds
        label.textAlignment = .center
        addSubview(label)
        applyStyle()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func prepareForReuse() {
        super.prepareForReuse()
        isSelectedListing = false
    }

    private func applyStyle() {
        let green = UIColor(AppTheme.current.primary)
        backgroundColor = isSelectedListing ? green : .white
        layer.borderColor = (isSelectedListing ? UIColor.white : UIColor.black.withAlphaComponent(0.08)).cgColor
        let config = UIImage.SymbolConfiguration(pointSize: 13, weight: .bold)
        let paw = NSTextAttachment(image: UIImage(systemName: "pawprint.fill", withConfiguration: config)!
            .withTintColor(isSelectedListing ? .white : green, renderingMode: .alwaysOriginal))
        label.attributedText = NSAttributedString(attachment: paw)
        transform = isSelectedListing ? CGAffineTransform(scaleX: 1.15, y: 1.15) : .identity
        zPriority = isSelectedListing ? .max : .defaultUnselected
    }
}

/// Group of nearby listings: green bubble with the number of listings.
final class ListingClusterView: MKAnnotationView {
    private let label = UILabel()

    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        collisionMode = .circle
        displayPriority = .defaultHigh
        label.textAlignment = .center
        label.textColor = .white
        addSubview(label)
        layer.borderColor = UIColor.white.cgColor
        layer.borderWidth = 3
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.25
        layer.shadowRadius = 5
        layer.shadowOffset = CGSize(width: 0, height: 2)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func prepareForDisplay() {
        super.prepareForDisplay()
        let count = (annotation as? MKClusterAnnotation)?.memberAnnotations.count ?? 0
        // Bigger groups get bigger bubbles.
        let size: CGFloat = count < 10 ? 40 : count < 100 ? 48 : 56
        frame = CGRect(x: 0, y: 0, width: size, height: size)
        layer.cornerRadius = size / 2
        backgroundColor = UIColor(AppTheme.current.primary)
        label.frame = bounds
        label.font = .systemFont(ofSize: count < 100 ? 16 : 14, weight: .heavy)
        label.text = count > 999 ? "999+" : "\(count)"
        accessibilityLabel = "\(count) listings"
    }
}
