//
//  MyListingsView.swift
//  Paw Sitters
//
//  "My listings" in Profile: the signed-in user's own listings, with a sheet
//  to edit (text, dates, location, environment, pets, photos) or delete them.
//

import SwiftUI
import FirebaseFirestore

struct MyListingsSection: View {
    let role: String
    @EnvironmentObject var firestoreService: FirestoreService
    @State private var editing: PetSittingListing?
    @StateObject private var imageCache = ImageCacheViewModel()
    private let theme = AppTheme.current

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("My listings", systemImage: "list.bullet.rectangle.portrait.fill")
                    .font(.system(.headline, design: .rounded))
                    .foregroundStyle(theme.text)
                Spacer()
                Text("\(firestoreService.myListings.count)")
                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
                    .foregroundStyle(theme.text.opacity(0.5))
            }

            if firestoreService.myListings.isEmpty {
                Text("You haven't published a listing yet. Tap + to create one.")
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(theme.text.opacity(0.55))
            } else {
                ForEach(firestoreService.myListings) { listing in
                    Divider()
                    Button {
                        editing = listing
                    } label: {
                        row(for: listing)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(18)
        .themedCard()
        .onAppear { firestoreService.listenToMyListings(role: role) }
        .sheet(item: $editing) { listing in
            EditListingSheet(listing: listing, role: role)
        }
    }

    private func row(for listing: PetSittingListing) -> some View {
        HStack(spacing: 12) {
            Group {
                if let url = listing.imageUrl, let image = imageCache.images[url] {
                    Image(uiImage: image).resizable().scaledToFill()
                } else {
                    theme.secondary.opacity(0.35)
                        .overlay(Image(systemName: "pawprint.fill").foregroundStyle(theme.primary.opacity(0.5)))
                        .onAppear { if let url = listing.imageUrl { imageCache.loadImage(from: url) } }
                }
            }
            .frame(width: 56, height: 56)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

            VStack(alignment: .leading, spacing: 3) {
                Text(listing.title.isEmpty ? "Untitled listing" : listing.title)
                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
                    .foregroundStyle(theme.text)
                    .lineLimit(2)
                Text(subtitle(for: listing))
                    .font(.caption)
                    .foregroundStyle(theme.text.opacity(0.55))
                    .lineLimit(1)
            }
            Spacer(minLength: 0)
            Image(systemName: "pencil")
                .foregroundStyle(theme.primary)
        }
        .contentShape(Rectangle())
    }

    private func subtitle(for listing: PetSittingListing) -> String {
        var parts: [String] = []
        if let location = listing.location, !location.isEmpty { parts.append(ListingFilters.city(from: location)) }
        if let range = listing.dateRange {
            parts.append("\(range.lowerBound.formatted(.dateTime.day().month(.abbreviated))) – \(range.upperBound.formatted(.dateTime.day().month(.abbreviated)))")
        } else {
            parts.append("Flexible dates")
        }
        return parts.joined(separator: " · ")
    }
}

struct EditListingSheet: View {
    let listing: PetSittingListing
    let role: String
    @EnvironmentObject var firestoreService: FirestoreService
    @EnvironmentObject var storageService: StorageService
    @Environment(\.dismiss) private var dismiss
    @StateObject private var locationViewModel = LocationViewModel()

    @State private var title = ""
    @State private var details = ""
    @State private var dateRange: ClosedRange<Date>?
    @State private var environment = ""
    @State private var pets: [String: Int] = [:]
    @State private var keptImageUrls: [String] = []
    @State private var newImages: [UIImage] = []
    @State private var isPickingImages = false
    @State private var isCalendarExpanded = false
    @State private var isSaving = false
    @State private var errorMessage: String?
    @State private var confirmDelete = false
    @State private var didLoad = false
    @FocusState private var focusedField: Field?
    private let theme = AppTheme.current

    private enum Field: Hashable { case title, details, location }

    private static let petKinds: [(key: String, label: String, icon: String)] = [
        ("dogs", "Dogs", "dog.fill"), ("cats", "Cats", "cat.fill"), ("birds", "Birds", "bird.fill"),
        ("hares", "Rabbits", "hare.fill"), ("others", "Other pets", "pawprint.fill")
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    section("Photos", icon: "photo.on.rectangle") { photosEditor }
                    section("Title", icon: "textformat") {
                        inputBox {
                            TextField("Listing title", text: $title, axis: .vertical)
                                .lineLimit(1...3)
                                .focused($focusedField, equals: .title)
                        }
                    }
                    section("Description", icon: "text.alignleft") {
                        inputBox {
                            TextField(role == "Sitter" ? "Your experience and what you offer"
                                                       : "Your home, your pets and their routine",
                                      text: $details, axis: .vertical)
                                .lineLimit(4...10)
                                .focused($focusedField, equals: .details)
                        }
                    }
                    section("Dates", icon: "calendar") { datesEditor }
                    section("Location", icon: "mappin.and.ellipse") { locationEditor }
                    section("Environment", icon: "leaf.fill") { environmentEditor }
                    section(role == "Sitter" ? "Pets you can care for" : "Your pets", icon: "pawprint.fill") { petsEditor }

                    if let errorMessage {
                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundStyle(.red)
                    }

                    Button(role: .destructive) {
                        confirmDelete = true
                    } label: {
                        Label("Delete listing", systemImage: "trash")
                            .font(.system(.subheadline, design: .rounded).weight(.semibold))
                            .foregroundStyle(.red)
                            .frame(maxWidth: .infinity)
                    }
                    .padding(.top, 4)
                }
                .padding(20)
            }
            .scrollDismissesKeyboard(.interactively)
            .background(theme.background.ignoresSafeArea())
            .safeAreaInset(edge: .bottom) {
                Button(action: save) {
                    Group {
                        if isSaving { ProgressView().tint(.white) } else { Text("Save changes") }
                    }
                    .themedButton()
                    .frame(maxWidth: .infinity)
                }
                .disabled(isSaving)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(.ultraThinMaterial)
            }
            .navigationTitle("Edit listing")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") { focusedField = nil }.fontWeight(.semibold)
                }
            }
            .sheet(isPresented: $isPickingImages) {
                ImagePicker(images: $newImages, isForMessaging: false)
            }
            .confirmationDialog("Delete this listing?", isPresented: $confirmDelete, titleVisibility: .visible) {
                Button("Delete listing", role: .destructive) { delete() }
            } message: {
                Text("It will be removed for everyone, together with its photos. Pending applications will be declined.")
            }
        }
        .interactiveDismissDisabled(isSaving)
        .onAppear(perform: load)
    }

    // MARK: - Editors

    private var photosEditor: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(keptImageUrls, id: \.self) { url in
                    AsyncImage(url: URL(string: url)) { image in
                        image.resizable().scaledToFill()
                    } placeholder: {
                        theme.secondary.opacity(0.35).overlay(ProgressView())
                    }
                    .photoTile { keptImageUrls.removeAll { $0 == url } }
                }
                ForEach(newImages.indices, id: \.self) { index in
                    Image(uiImage: newImages[index]).resizable().scaledToFill()
                        .photoTile { newImages.remove(at: index) }
                }
                Button {
                    isPickingImages = true
                } label: {
                    VStack(spacing: 6) {
                        Image(systemName: "plus").font(.system(size: 22, weight: .semibold))
                        Text("Add").font(.caption.weight(.semibold))
                    }
                    .foregroundStyle(theme.primary)
                    .frame(width: 96, height: 96)
                    .background(Color.white, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(theme.secondary, style: StrokeStyle(lineWidth: 1.5, dash: [5])))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var datesEditor: some View {
        VStack(spacing: 10) {
            Button {
                withAnimation(.snappy) { isCalendarExpanded.toggle() }
            } label: {
                HStack {
                    Text(dateSummary)
                        .foregroundStyle(dateRange == nil ? theme.text.opacity(0.5) : theme.text)
                    Spacer()
                    if dateRange != nil {
                        Button {
                            dateRange = nil
                        } label: {
                            Image(systemName: "xmark.circle.fill").foregroundStyle(theme.text.opacity(0.35))
                        }
                        .accessibilityLabel("Clear dates")
                    }
                    Image(systemName: "chevron.down")
                        .rotationEffect(.degrees(isCalendarExpanded ? 180 : 0))
                        .foregroundStyle(theme.text.opacity(0.5))
                }
                .font(.system(.subheadline, design: .rounded).weight(.semibold))
                .padding(12)
                .background(Color.white, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .buttonStyle(.plain)
            if isCalendarExpanded {
                HorizonCalendar(calendar: .current, monthsLayout: .vertical, selectedDateRange: $dateRange)
                    .frame(height: 340)
                    .background(Color.white, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
        }
    }

    private var locationEditor: some View {
        VStack(alignment: .leading, spacing: 0) {
            inputBox {
                TextField("City", text: $locationViewModel.location)
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled()
                    .focused($focusedField, equals: .location)
            }
            if focusedField == .location && !locationViewModel.citySuggestions.isEmpty {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(locationViewModel.citySuggestions.prefix(4)) { city in
                        Button {
                            locationViewModel.location = city.name
                            locationViewModel.fetchCoordinates(for: city)
                            locationViewModel.citySuggestions = []
                            focusedField = nil
                        } label: {
                            Label(city.name, systemImage: "mappin")
                                .font(.system(.subheadline, design: .rounded))
                                .foregroundStyle(theme.text)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(10)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .background(Color.white, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .padding(.top, 6)
            }
        }
    }

    private var environmentEditor: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), spacing: 8)], spacing: 8) {
            ForEach(ListingFilters.environments, id: \.name) { option in
                let isSelected = environment == option.name
                Button {
                    environment = isSelected ? "" : option.name
                } label: {
                    Label(option.name, systemImage: option.icon)
                        .font(.system(.caption, design: .rounded).weight(.semibold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .foregroundStyle(isSelected ? .white : theme.text)
                        .background(isSelected ? theme.primary : Color.white,
                                    in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var petsEditor: some View {
        VStack(spacing: 0) {
            ForEach(Self.petKinds, id: \.key) { kind in
                HStack {
                    Label(kind.label, systemImage: kind.icon)
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundStyle(theme.text)
                    Spacer()
                    Stepper(value: Binding(get: { pets[kind.key] ?? 0 }, set: { pets[kind.key] = $0 }), in: 0...20) {
                        Text("\(pets[kind.key] ?? 0)")
                            .font(.system(.subheadline, design: .rounded).weight(.semibold).monospacedDigit())
                            .foregroundStyle(theme.text)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                    .frame(width: 150)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                if kind.key != Self.petKinds.last?.key { Divider().padding(.leading, 12) }
            }
        }
        .background(Color.white, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func section<Content: View>(_ title: String, icon: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: icon)
                .font(.system(.headline, design: .rounded))
                .foregroundStyle(theme.text)
            content()
        }
    }

    private func inputBox<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .font(.system(.body, design: .rounded))
            .padding(12)
            .background(Color.white, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private var dateSummary: String {
        guard let range = dateRange else { return "Flexible dates" }
        return "\(range.lowerBound.formatted(.dateTime.day().month(.abbreviated))) – \(range.upperBound.formatted(.dateTime.day().month(.abbreviated).year()))"
    }

    // MARK: - Actions

    private func load() {
        guard !didLoad else { return }
        didLoad = true
        title = listing.title
        details = listing.description
        dateRange = listing.dateRange
        environment = listing.environment
        locationViewModel.location = listing.location ?? ""
        keptImageUrls = (listing.imageUrls ?? []).filter { !$0.isEmpty }
        let current = listing.pets
        pets = ["dogs": Int(current?.numDogs ?? "") ?? 0, "cats": Int(current?.numCats ?? "") ?? 0,
                "birds": Int(current?.numBirds ?? "") ?? 0, "hares": Int(current?.numHares ?? "") ?? 0,
                "others": Int(current?.numOthers ?? "") ?? 0]
        // Pre-filling the field shouldn't pop up city suggestions.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { locationViewModel.citySuggestions = [] }
    }

    private func save() {
        focusedField = nil
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else {
            errorMessage = "Please enter a title."
            return
        }
        isSaving = true
        errorMessage = nil
        Task {
            do {
                var imageUrls = keptImageUrls
                for image in newImages {
                    imageUrls.append(try await upload(image))
                }
                var fields: [String: Any] = [
                    "title": trimmedTitle,
                    "description": details.trimmingCharacters(in: .whitespacesAndNewlines),
                    "environment": environment,
                    "location": locationViewModel.location.trimmingCharacters(in: .whitespacesAndNewlines),
                    "imageUrls": imageUrls,
                    // Firestore needs NSNull (not a Swift nil) to store an empty value.
                    "dateRange": dateRange.map { ["start": Timestamp(date: $0.lowerBound), "end": Timestamp(date: $0.upperBound)] } ?? NSNull()
                ]
                for (key, count) in pets { fields["pets.\(key)"] = count }
                if locationViewModel.location != (listing.location ?? "") {
                    // New city: use its coordinates if a suggestion was picked, otherwise let the map look it up.
                    fields["latitude"] = locationViewModel.selectedCityCoordinates?.latitude ?? NSNull()
                    fields["longitude"] = locationViewModel.selectedCityCoordinates?.longitude ?? NSNull()
                }
                try await firestoreService.updateListing(listing, role: role, fields: fields)
                // Photos removed in this edit are deleted from Storage.
                let removed = Set(listing.imageUrls ?? []).subtracting(imageUrls)
                for url in removed where url.contains("firebasestorage") {
                    try? await StorageService.delete(url: url)
                }
                isSaving = false
                dismiss()
            } catch {
                isSaving = false
                errorMessage = "Couldn't save your changes: \(error.localizedDescription)"
            }
        }
    }

    private func upload(_ image: UIImage) async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            storageService.uploadImage(image, path: "listing_images/\(UUID().uuidString).jpg") { result in
                continuation.resume(with: result)
            }
        }
    }

    private func delete() {
        isSaving = true
        Task {
            do {
                try await firestoreService.deleteListing(listing, role: role)
                isSaving = false
                dismiss()
            } catch {
                isSaving = false
                errorMessage = "Couldn't delete the listing: \(error.localizedDescription)"
            }
        }
    }
}

private extension View {
    /// 96×96 rounded photo with a remove button.
    func photoTile(onRemove: @escaping () -> Void) -> some View {
        self
            .frame(width: 96, height: 96)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(alignment: .topTrailing) {
                Button(action: onRemove) {
                    Image(systemName: "xmark")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 22, height: 22)
                        .background(.black.opacity(0.6), in: Circle())
                }
                .padding(5)
                .accessibilityLabel("Remove photo")
            }
    }
}
