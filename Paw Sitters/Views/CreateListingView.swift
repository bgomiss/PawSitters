//
//  CreateListingView.swift
//  Paw Sitters
//
//  Created by aycan duskun on 13.07.2024.
//

import SwiftUI
import HorizonCalendar
import FirebaseFirestore

//enum ListingDetails {
//    case title
//    case date
//    case pets
//    case description
//    case location
//    case environment
//}

struct CreateListingView: View {
    
    @State private var name: String = ""
    var role: String?
    /// Called after the user acknowledges a successful publish.
    var onPublished: () -> Void = {}
    @State private var selectedDateRange: ClosedRange<Date>?
    private let calendar = Calendar.current
    private let startDate: Date
    private let endDate: Date
    @State private var images: [UIImage] = []
    @State private var listings = PetSittingListing(documentId: "", data: [:])
    @State private var showingImagePicker = false
    @State private var showingDatePicker = false
    @StateObject private var viewModel = CreateListingViewModel(locationViewModel: LocationViewModel())
    @StateObject private var locationViewModel = LocationViewModel()
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var firestoreService: FirestoreService
    @EnvironmentObject var storageService: StorageService
    @EnvironmentObject var userProfileService: UserProfileService
    @EnvironmentObject var navigationPathManager: NavigationPathManager
    @Environment(\.presentationMode) var presentationMode
    
    
    init(role: String?, onPublished: @escaping () -> Void = {}) {
        self.onPublished = onPublished
        let locationVVM = LocationViewModel()
        _locationViewModel = StateObject(wrappedValue: locationVVM)
        _viewModel = StateObject(wrappedValue: CreateListingViewModel(locationViewModel: locationVVM))
        self.startDate = calendar.date(from: DateComponents(year: 2023, month: 01, day: 01))!
        self.endDate = calendar.date(byAdding: .year, value: 2, to: Date())!
        self.role = role
    }
    
    @FocusState private var focusedField: Field?
    /// The suggestion the user picked; hides suggestions until they type again.
    @State private var pickedLocation: String?
    private let theme = AppTheme.current
    
    private enum Field: Hashable { case title, description, location }
    
    /// Scroll target a little below the top, so the open card clears the status
    /// bar and the previous card's summary stays visible above it.
    private static let scrollAnchor = UnitPoint(x: 0.5, y: 0.08)
    
    private static let petKinds: [(label: String, icon: String, keyPath: WritableKeyPath<PetCount, Int>)] = [
        ("Dogs", "dog.fill", \.dogs), ("Cats", "cat.fill", \.cats), ("Birds", "bird.fill", \.birds), ("Rabbits", "hare.fill", \.hares),
        ("Fish", "fish.fill", \.fish), ("Other pets", "pawprint.fill", \.others)
    ]
    
    var body: some View {
        // Airbnb-style: one card open at a time, the others show a one-line summary.
        ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(ListingSection.allCases, id: \.self) { section in
                        sectionCard(for: section)
                            .id(section)
                    }
                    
                    imageSection
                    
                    Button {
                        focusedField = nil
                        viewModel.publishListing(role: role ?? userProfileService.userProfile?.role ?? "Owner",
                                                 ownerName: userProfileService.userProfile?.name ?? "",
                                                 authService: authService, firestoreService: firestoreService, storageService: storageService)
                    } label: {
                        Group {
                            if viewModel.isPublishing {
                                ProgressView().tint(.white)
                            } else {
                                Label("Publish", systemImage: "paperplane.fill")
                            }
                        }
                        .themedButton(AppTheme.current.accent)
                    }
                    .disabled(viewModel.isPublishing)
                    .padding(.top, 8)
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                // Room to scroll the last card above the keyboard and the tab bar.
                .padding(.bottom, 140)
            }
            .scrollDismissesKeyboard(.interactively)
            .onChange(of: viewModel.selectedOption) { _, section in
                focusedField = defaultField(for: section)
                // Wait for the expand animation, then bring the open card to the top.
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    withAnimation(.snappy) { proxy.scrollTo(section, anchor: Self.scrollAnchor) }
                }
            }
            .onChange(of: focusedField) { _, field in
                // The keyboard shrinks the visible area; keep the active card in view.
                guard field != nil else { return }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                    withAnimation(.snappy) { proxy.scrollTo(viewModel.selectedOption, anchor: Self.scrollAnchor) }
                }
            }
        }
        .navigationBarTitle("Create Listing")
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                if let next = nextSection(after: viewModel.selectedOption) {
                    Button("Next") { open(next) }
                }
                Spacer()
                Button("Done") { focusedField = nil }
                    .fontWeight(.semibold)
            }
        }
        .alert(isPresented: $viewModel.showingAlert) {
            Alert(title: Text(viewModel.alertTitle),
                  message: Text(viewModel.alertMessage),
                  dismissButton: .default(Text("OK")) {
                if viewModel.alertTitle == "Success" {
                    viewModel.reset()
                    selectedDateRange = nil
                    pickedLocation = nil
                    onPublished()
                }
            })
        }
        .sheet(isPresented: $viewModel.showingImagePicker) {
            ImagePicker(images: $viewModel.listingDetails.images, isForMessaging: false)
        }
    }
    
    // MARK: - Cards
    
    @ViewBuilder
    private func sectionCard(for section: ListingSection) -> some View {
        let isOpen = viewModel.selectedOption == section
        VStack(alignment: .leading, spacing: 14) {
            if isOpen {
                Text(question(for: section))
                    .font(.system(.title3, design: .rounded).weight(.bold))
                    .foregroundStyle(theme.text)
                switch section {
                case .title: titleSection
                case .date: dateSection
                case .pets: petsSection
                case .description: descriptionSection
                case .location: locationSection
                case .environment: environmentSection
                }
                if let next = nextSection(after: section) {
                    HStack {
                        Spacer()
                        Button {
                            open(next)
                        } label: {
                            Label("Next", systemImage: "arrow.right")
                                .labelStyle(TrailingIconLabelStyle())
                                .font(.system(.subheadline, design: .rounded).weight(.semibold))
                                .padding(.horizontal, 16)
                                .padding(.vertical, 9)
                                .foregroundStyle(.white)
                                .background(theme.text, in: Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
            } else {
                Button {
                    open(section)
                } label: {
                    CollapsedPickerView(headline: section.rawValue,
                                        placeholder: summary(for: section) ?? placeholderFor(section),
                                        isFilled: summary(for: section) != nil)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(isOpen ? 18 : 16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white, in: RoundedRectangle(cornerRadius: isOpen ? 22 : 16, style: .continuous))
        .shadow(color: .black.opacity(isOpen ? 0.12 : 0.06), radius: isOpen ? 14 : 6, y: isOpen ? 6 : 2)
    }
    
    var titleSection: some View {
        // Single line so the return key moves on instead of adding a new line.
        TextField("e.g. Dog sitter needed for two labradors", text: $viewModel.listingDetails.title)
            .focused($focusedField, equals: .title)
            .submitLabel(.next)
            .onSubmit { open(.date) }
            .modifier(ThemedInputModifier())
    }
    
    var dateSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HorizonCalendar(calendar: calendar, monthsLayout: .vertical, selectedDateRange: $selectedDateRange)
                .frame(height: 340)
            if selectedDateRange != nil {
                Button("Clear dates") { selectedDateRange = nil }
                    .font(.system(.footnote, design: .rounded).weight(.semibold))
                    .foregroundStyle(theme.accent)
            }
        }
        .onChange(of: selectedDateRange) { _, newValue in
            viewModel.listingDetails.dateRange = newValue
        }
    }
    
    var petsSection: some View {
        VStack(spacing: 0) {
            ForEach(Self.petKinds, id: \.label) { kind in
                HStack {
                    Label(kind.label, systemImage: kind.icon)
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundStyle(theme.text)
                    Spacer()
                    Stepper(value: $viewModel.listingDetails.pets[dynamicMember: kind.keyPath], in: 0...20) {
                        Text("\(viewModel.listingDetails.pets[keyPath: kind.keyPath])")
                            .font(.system(.subheadline, design: .rounded).weight(.semibold).monospacedDigit())
                            .foregroundStyle(theme.text)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                    .frame(width: 150)
                }
                .padding(.vertical, 6)
                if kind.label != Self.petKinds.last?.label { Divider() }
            }
        }
    }
    
    var descriptionSection: some View {
        TextField(role == "Sitter" ? "Your experience with pets and what you offer"
                                   : "Your home, your pets and their routine",
                  text: $viewModel.listingDetails.description, axis: .vertical)
            .lineLimit(4...10)
            .focused($focusedField, equals: .description)
            .modifier(ThemedInputModifier())
    }
    
    var locationSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(theme.text.opacity(0.5))
                TextField("Search a city", text: $locationViewModel.location)
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled()
                    .focused($focusedField, equals: .location)
                    .submitLabel(.done)
                    .onSubmit { focusedField = nil }
                if !locationViewModel.location.isEmpty {
                    Button {
                        locationViewModel.location = ""
                        locationViewModel.selectedCityCoordinates = nil
                        pickedLocation = nil
                        focusedField = .location
                    } label: {
                        Image(systemName: "xmark.circle.fill").foregroundStyle(theme.text.opacity(0.35))
                    }
                    .accessibilityLabel("Clear city")
                }
            }
            .modifier(ThemedInputModifier())
            
            if !locationViewModel.citySuggestions.isEmpty, locationViewModel.location != pickedLocation,
               !locationViewModel.location.isEmpty {
                CitySuggestionList(cities: locationViewModel.citySuggestions) { city in
                    pickedLocation = city.name
                    locationViewModel.location = city.name
                    locationViewModel.fetchCoordinates(for: city)
                    locationViewModel.citySuggestions = []
                    focusedField = nil
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            } else if let pickedLocation, pickedLocation == locationViewModel.location {
                Label("Shown around \(ListingFilters.city(from: pickedLocation)) on the map", systemImage: "checkmark.circle.fill")
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(theme.primary)
            }
        }
        .animation(.snappy, value: locationViewModel.citySuggestions.count)
    }
    
    var environmentSection: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), spacing: 8)], spacing: 8) {
            ForEach(ListingFilters.environments, id: \.name) { option in
                let isSelected = viewModel.listingDetails.environment == option.name
                Button {
                    viewModel.listingDetails.environment = isSelected ? "" : option.name
                } label: {
                    VStack(spacing: 6) {
                        Image(systemName: option.icon).font(.system(size: 18))
                        Text(option.name)
                            .font(.system(.caption, design: .rounded).weight(.semibold))
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .foregroundStyle(isSelected ? .white : theme.text)
                    .background(isSelected ? theme.primary : theme.background,
                                in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
    }
    
    var imageSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Photos")
                .font(.system(.headline, design: .rounded))
                .foregroundStyle(theme.text)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(viewModel.listingDetails.images.indices, id: \.self) { index in
                        Image(uiImage: viewModel.listingDetails.images[index])
                            .resizable()
                            .scaledToFill()
                            .frame(width: 96, height: 96)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .overlay(alignment: .topTrailing) {
                                Button {
                                    viewModel.listingDetails.images.remove(at: index)
                                } label: {
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
                    Button {
                        viewModel.showingImagePicker = true
                    } label: {
                        VStack(spacing: 6) {
                            Image(systemName: "plus").font(.system(size: 22, weight: .semibold))
                            Text("Add").font(.caption.weight(.semibold))
                        }
                        .foregroundStyle(theme.primary)
                        .frame(width: 96, height: 96)
                        .background(theme.background, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .strokeBorder(theme.secondary, style: StrokeStyle(lineWidth: 1.5, dash: [5])))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.06), radius: 6, y: 2)
    }
    
    // MARK: - Helpers
    
    private func open(_ section: ListingSection) {
        withAnimation(.snappy) { viewModel.selectedOption = section }
    }
    
    private func nextSection(after section: ListingSection) -> ListingSection? {
        let all = ListingSection.allCases
        guard let index = all.firstIndex(of: section), index + 1 < all.count else { return nil }
        return all[index + 1]
    }
    
    private func defaultField(for section: ListingSection) -> Field? {
        switch section {
        case .title: return .title
        case .description: return .description
        case .location: return .location
        default: return nil
        }
    }
    
    private func question(for section: ListingSection) -> String {
        switch section {
        case .title: return "Give your listing a title"
        case .date: return "When?"
        case .pets: return role == "Sitter" ? "Which pets can you care for?" : "Which pets need care?"
        case .description: return "Tell people more"
        case .location: return "Where?"
        case .environment: return "What's the area like?"
        }
    }
    
    /// One-line summary for a closed card, or nil when nothing is filled in yet.
    private func summary(for section: ListingSection) -> String? {
        let details = viewModel.listingDetails
        switch section {
        case .title:
            let title = details.title.trimmingCharacters(in: .whitespacesAndNewlines)
            return title.isEmpty ? nil : title
        case .date:
            guard let range = details.dateRange else { return nil }
            return "\(range.lowerBound.formatted(.dateTime.day().month(.abbreviated))) – \(range.upperBound.formatted(.dateTime.day().month(.abbreviated)))"
        case .pets:
            let parts = Self.petKinds.compactMap { kind -> String? in
                let count = details.pets[keyPath: kind.keyPath]
                return count > 0 ? "\(count) \(kind.label.lowercased())" : nil
            }
            return parts.isEmpty ? nil : parts.joined(separator: ", ")
        case .description:
            let text = details.description.trimmingCharacters(in: .whitespacesAndNewlines)
            return text.isEmpty ? nil : text
        case .location:
            let city = locationViewModel.location.trimmingCharacters(in: .whitespacesAndNewlines)
            return city.isEmpty ? nil : city
        case .environment:
            return details.environment.isEmpty ? nil : details.environment
        }
    }
    
    private func placeholderFor(_ section: ListingSection) -> String {
        switch section {
        case .title: return "Add a title"
        case .date: return "Add dates"
        case .pets: return "Add pets"
        case .description: return "Add details"
        case .location: return "Add a city"
        case .environment: return "Choose one"
        }
    }
}

/// Text field look used across the create-listing cards.
struct ThemedInputModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.system(.body, design: .rounded))
            .padding(12)
            .background(AppTheme.current.background, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(AppTheme.current.secondary.opacity(0.6), lineWidth: 1))
    }
}

/// Puts a label's icon after its title ("Next →").
struct TrailingIconLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 6) {
            configuration.title
            configuration.icon
        }
    }
}

struct CreateListingView_Previews: PreviewProvider {
    static var previews: some View {
        CreateListingView(role: "Sitter")
        .environmentObject(UserProfileService(authService: AuthService()))
        .environmentObject(AuthService())
        .environmentObject(FirestoreService())
        .environmentObject(NavigationPathManager())
        .environmentObject(StorageService())
    }
}

struct CollapsibleDestinationViewModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding()
            .background(.white)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: .black.opacity(0.08), radius: 8, y: 3)
            .padding()
    }
}

struct CollapsedPickerView: View {
    let headline: String
    let placeholder: String
    var isFilled = false
    
    var body: some View {
        HStack(spacing: 12) {
            Text(headline)
                .foregroundStyle(AppTheme.current.text.opacity(0.55))
            Spacer(minLength: 8)
            Text(placeholder)
                .foregroundStyle(isFilled ? AppTheme.current.text : AppTheme.current.text.opacity(0.4))
                .lineLimit(1)
            if isFilled {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(AppTheme.current.primary)
            }
        }
        .font(.system(.subheadline, design: .rounded).weight(.semibold))
        .contentShape(Rectangle())
    }
}

//                    if section.isEnabled {
//                        switch section {
//                        case .title:
//                            titleSection
//                        case .description:
//                            descriptionSection
//                        case .location:
//                            locationSection
//                        case .startDate:
//                            startDateSection
//                        }
//                    }
//                HStack {
                    
//                    Spacer()
//                    
//                    if !title.isEmpty {
//                        Button("Clear") {
//                            title = ""
//                        }
//                        .foregroundStyle(.black)
//                        .font(.subheadline)
//                        .fontWeight(.bold)
//                    }
//                }
//                .padding()
// MARK: - Title
//                VStack(alignment: .leading) {
//                    if selectedOption == .title {
//                        Text("Title")
//                            .font(.title2)
//                            .fontWeight(.semibold)
//                        HStack {
//                            TextField("Enter Title", text: $title)
//                                .font(.subheadline)
//                        }
//                        .frame(height: 44)
//                        .padding(.horizontal)
//                        .overlay {
//                            RoundedRectangle(cornerRadius: 8)
//                                .stroke(lineWidth: 1.0)
//                                .foregroundStyle(Color(.systemGray4))
//                        }
//                    } else {
//                        CollapsedPickerView(headline: "Title", placeholder: "Enter Title")
//                    }
//                }
//                .modifier(CollapsibleDestinationViewModifier())
//                .frame(height: selectedOption == .title ? 120 : 64)
//                .onTapGesture {
//                    withAnimation(.snappy) { selectedOption = .title }
//                }
//// MARK: - Date
//                VStack(alignment: .leading) {
//                    if selectedOption == .date {
//                        HorizonCalendar(calendar: calendar, monthsLayout: .vertical, selectedDateRange: $selectedDateRange)
//                    } else {
//                        CollapsedPickerView(headline: "When", placeholder: "Add Dates")
//                    }
//                }
//                .modifier(CollapsibleDestinationViewModifier())
//                .frame(height: selectedOption == .date ? 300 : 64)
//                .onTapGesture {
//                    withAnimation(.snappy) { selectedOption = .date }
//                }
//                
//// MARK: - Pets
//                VStack(alignment: .leading) {
//                    if selectedOption == .pets {
//                        Text("What are the pets?")
//                            .font(.title)
//                            .fontWeight(.semibold)
//                        Stepper {
//                            HStack {
//                                Image(systemName: "dog.fill")
//                                Text("\(numDogs)")
//                            }
//                        } onIncrement: {
//                            numDogs += 1
//                        } onDecrement: {
//                            guard numDogs > 0 else { return }
//                            numDogs -= 1                    }
//                        
//                        Stepper {
//                            HStack {
//                                Image(systemName: "bird.fill")
//                                Text("\(numBirds)")
//                            }
//                        } onIncrement: {
//                            numBirds += 1
//                        } onDecrement: {
//                            guard numBirds > 0 else { return }
//                            numBirds -= 1                    }
//                        
//                        Stepper {
//                            HStack {
//                                Image(systemName: "hare.fill")
//                                Text("\(numHares)")
//                            }
//                        } onIncrement: {
//                            numHares += 1
//                        } onDecrement: {
//                            guard numHares > 0 else { return }
//                            numHares -= 1                    }
//                        Stepper {
//                            HStack {
//                                Image(systemName: "fish.fill")
//                                Text("\(numFish)")
//                            }
//                        } onIncrement: {
//                            numFish += 1
//                        } onDecrement: {
//                            guard numFish > 0 else { return }
//                            numFish -= 1                    }
//                        
//                        Stepper {
//                            HStack {
//                                Image(systemName: "pawprint.fill")
//                                Text("\(numOthers)")
//                            }
//                        } onIncrement: {
//                            numOthers += 1
//                        } onDecrement: {
//                            guard numOthers > 0 else { return }
//                            numOthers -= 1                    }
//                        
//                    } else {
//                        CollapsedPickerView(headline: "Pets", placeholder: "Choose the pets")
//                    }
//                }
//                .modifier(CollapsibleDestinationViewModifier())
//                .frame(height: selectedOption == .pets ? 200 : 64)
//                .padding(EdgeInsets(top: selectedOption == .pets ? 40 : 0, leading: 0, bottom: selectedOption == .pets ? 40 : 0, trailing: 0))
//                .onTapGesture {
//                    withAnimation { selectedOption = .pets }
//                }
//// MARK: - Description
//                VStack(alignment: .leading) {
//                    if selectedOption == .description {
//                        ZStack(alignment: .topLeading) {
//                            if description.isEmpty {
//                                Text("Enter a description")
//                                    .foregroundColor(.gray)
//                                    .padding(.top, 8)
//                                    .padding(.horizontal, 4)
//                            }
//                            TextEditor(text: $description)
//                                .frame(height: 150)
//                                .onChange(of: description) {_, newValue in
//                                    if newValue.count > 150 {
//                                        description = String(newValue.prefix(150))
//                                    }
//                                }
//                        }
//                    } else {
//                        CollapsedPickerView(headline: "Description", placeholder: "Enter Description")
//                    }
//                }
//                .modifier(CollapsibleDestinationViewModifier())
//                .frame(height: selectedOption == .description ? 180 : 64)
//                .onTapGesture {
//                    withAnimation { selectedOption = .description }
//                }
//// MARK: - Location
//                VStack(alignment: .leading) {
//                    if selectedOption == .location {
//                        Text("Location")
//                            .font(.title2)
//                            .fontWeight(.semibold)
//                        HStack {
//                            TextField("Choose your location", text: $viewModel.location)
//                                .font(.subheadline)
//                        }
//                        .frame(height: 44)
//                        .padding(.horizontal)
//                        .overlay {
//                            RoundedRectangle(cornerRadius: 8)
//                                .stroke(lineWidth: 1.0)
//                                .foregroundStyle(Color(.systemGray4))
//                        }
//                        
//                        if !viewModel.citySuggestions.isEmpty {
//                            List(viewModel.citySuggestions) { city in
//                                    Text(city.name)
//                                        .onTapGesture {
//                                            viewModel.location = city.name
//                                            viewModel.fetchCoordinates(for: city)
//                                            viewModel.citySuggestions = []
//                                }
//                            }
//                        }
//                    } else {
//                        CollapsedPickerView(headline: "Location", placeholder: "Choose the Location")
//                    }
//                }
//                .modifier(CollapsibleDestinationViewModifier())
//                .frame(height: selectedOption == .location ? 280 : 64)
//                .onTapGesture {
//                    withAnimation(.snappy) { selectedOption = .location }
//                }
//// MARK: - Environment
//                VStack(alignment: .leading) {
//                    if selectedOption == .environment {
//                        Text("Environment")
//                            .font(.title2)
//                            .fontWeight(.semibold)
//                        HStack {
//                            Menu {
//                                    Button("Beachside") { environment = "Beachside" }
//                                    Button("Countryside") { environment = "Countryside" }
//                                    Button("Forestside") { environment = "Forestside" }
//                                    Button("Urban") { environment = "Urban" }
//                                    Button("Suburban") { environment = "Suburban" }
//                                    Button("Mountainous") { environment = "Mountainous" }
//                                    Button("Lakeside") { environment = "Lakeside" }
//                                    Button("Rural") { environment = "Rural" }
//                                    Button("Coastal") { environment = "Coastal" }
//                                    Button("Desert") { environment = "Desert" }
//                                } label: {
//                                    Text(environment.isEmpty ? "Choose the environment" : environment)
//                                        .font(.subheadline)
//                                        .foregroundColor(.primary)
//                                        .padding(.horizontal)
//                                        .frame(maxWidth: .infinity, alignment: .leading)
//                                        .cornerRadius(8)
//                                }
//                        }
//                        .frame(height: 44)
//                        .padding(.horizontal)
//                        .overlay {
//                            RoundedRectangle(cornerRadius: 8)
//                                .stroke(lineWidth: 1.0)
//                                .foregroundStyle(Color(.systemGray4))
//                        }
//                    } else {
//                        CollapsedPickerView(headline: "Environment", placeholder: "Choose the Location")
//                    }
//                }
//                .modifier(CollapsibleDestinationViewModifier())
//                .frame(height: selectedOption == .environment ? 120 : 64)
//                .padding(.bottom)
//                .onTapGesture {
//                    withAnimation(.snappy) { selectedOption = .environment }
//                }
//                
//                if !images.isEmpty {
//                    ScrollView(.horizontal) {
//                        HStack {
//                            ForEach(images, id: \.self) { image in
//                                Image(uiImage: image)
//                                    .resizable()
//                                    .frame(width: 100, height: 100)
//                                    .clipShape(RoundedRectangle(cornerRadius: 10))
//                                    .padding(4)
//                            }
//                        }
//                    }
//                }
//                
//                Button("Choose Listing Images ") {
//                    showingImagePicker = true
//                }
//                .modifier(CollapsibleDestinationViewModifier())
//                .padding(.bottom, 1)
//                
//                Button("Publish") {
//                    uploadImagesAndPublishListing()
//                }
//                .modifier(CollapsibleDestinationViewModifier())
//                .alert(isPresented: $showingAlert) {
//                    Alert(
//                        title: Text(alertTitle),
//                        message: Text(alertMessage),
//                        dismissButton: .default(Text("OK")) {
//                            presentationMode.wrappedValue.dismiss()
//                        }
//                    )
//                }
//                
//                .navigationBarItems(leading: Text("Please Enter The Details Below")
//                    .font(.custom("HelveticaNeue-Thin", size: 16))
//                    .foregroundColor(.teal)
//                    .fontWeight(.bold)
//                    .padding(.horizontal, 15)
//                )
//                .sheet(isPresented: $showingImagePicker) {
//                    ImagePicker(images: $images, isForMessaging: false)
//                }
//                Spacer()
//            }
//        }
//        
//    }
//    

//private func uploadImagesAndPublishListing() {
//    var imageUrls: [String] = []
//    let dispatchGroup = DispatchGroup()
//    
//    for image in images {
//        dispatchGroup.enter()
//        storageService.uploadImage(image, path: "listing_images/\(UUID().uuidString).jpg") { result in
//            switch result {
//            case .success(let imageUrl):
//                imageUrls.append(imageUrl)
//            case .failure(let error):
//                print("Error uploading image: \(error.localizedDescription)")
//            }
//            dispatchGroup.leave()
//        }
//    }
//    
//    dispatchGroup.notify(queue: .main) {
//        self.publishListing(imageUrls: imageUrls)
//    }
//}

//private func publishListing(imageUrls: [String]) {
//    let ownerId = authService.user?.uid ?? ""
//    let pets = [
//            "birds": numBirds,
//            "dogs": numDogs,
//            "hares": numHares,
//            "fish": numFish,
//            "others": numOthers
//    ] as [String : Any]
//        let dateRangeDict: [String: Any]?
//        if let dateRange = selectedDateRange {
//            dateRangeDict = [
//                "start": Timestamp(date: dateRange.lowerBound),
//                "end": Timestamp(date: dateRange.upperBound)
//            ]
//        } else {
//            dateRangeDict = nil
//        }
//    
//    let listingData = [
//        "title": title,
//        "description": description,
//        "name": name,
//        "timestamp": Timestamp(date: Date()),
//        "dateRange": dateRangeDict as Any,
//        "imageUrls": imageUrls,
//        "role": role ?? "Sitter",
//        "ownerId": ownerId,
//        "location": viewModel.location,
//        "latitude": viewModel.selectedCityCoordinates?.latitude as Any,
//        "longitude": viewModel.selectedCityCoordinates?.longitude as Any,
//        "pets": pets
//    ] as [String : Any]
//
//    
//    firestoreService.addListing(role ?? "Sitter", listingData: listingData) { result in
//        switch result {
//        case .success():
//            alertTitle = "Success"
//            alertMessage = "Listing published successfully"
//            showingAlert = true
//            print("SAVED SUCCESSFULLY")
//        case .failure(let error):
//            alertTitle = "Error"
//            alertMessage = error.localizedDescription
//            showingAlert = true
//            print(alertMessage)
//         }
//      }
//   }
//}



    



