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
    
    
    init(role: String?) {
        let locationVVM = LocationViewModel()
        _locationViewModel = StateObject(wrappedValue: locationVVM)
        _viewModel = StateObject(wrappedValue: CreateListingViewModel(locationViewModel: locationVVM))
        self.startDate = calendar.date(from: DateComponents(year: 2023, month: 01, day: 01))!
        self.endDate = calendar.date(from: DateComponents(year: 2026, month: 12, day: 31))!
        self.role = role
    }
    
    var body: some View {
        ScrollView {
            VStack {
                ForEach(ListingSection.allCases, id: \.self) { section in
                    sectionView(for: section)
                }
                
                imageSection
                
                Button("Publish") {
                    viewModel.publishListing(authService: authService, firestoreService: firestoreService, storageService: storageService)
                }
                .modifier(CollapsibleDestinationViewModifier())
                .padding(.top, 1)
            }
        }
        .navigationBarTitle("Create Listing")
        .alert(isPresented: $viewModel.showingAlert) {
            Alert(title: Text(viewModel.alertTitle),
                  message: Text(viewModel.alertMessage),
                  dismissButton: .default(Text("OK")) {
                if viewModel.alertTitle == "Success" {
                    presentationMode.wrappedValue.dismiss()
                }
            })
        }
        .sheet(isPresented: $viewModel.showingImagePicker) {
            ImagePicker(images: $viewModel.listingDetails.images, isForMessaging: false)
        }
    }
    
    @ViewBuilder
    func sectionView(for section: ListingSection) -> some View {
        VStack(alignment: .leading) {
            Text(section.rawValue)
                .font(.title2)
                .fontWeight(.semibold)
            
            if viewModel.selectedOption == section {
                switch section {
                case .title: titleSection
                case .date:  dateSection
                case .pets:  petsSection
                case .description: descriptionSection
                case .location: locationSection
                case .environment: environmentSection
                }
                } else {
                    CollapsedPickerView(headline: section.rawValue, placeholder: placeholderFor(section))
                }
            }
            .modifier(CollapsibleDestinationViewModifier())
            .frame(height: viewModel.selectedOption == section ? nil : 64)
            .onTapGesture {
                withAnimation(.snappy) {
                    viewModel.selectedOption = section
            }
        }
    }
    
    var titleSection: some View {
        TextField("Enter Title", text: $viewModel.listingDetails.title)
            .textFieldStyle(RoundedBorderTextFieldStyle())
    }
    
    var dateSection: some View {
        VStack {
           // if viewModel.listingDetails.dateRange != nil {
                HorizonCalendar(calendar: calendar, monthsLayout: .vertical, selectedDateRange: $selectedDateRange)
           // }
        }
        .onChange(of: selectedDateRange) { _, newValue in
                viewModel.listingDetails.dateRange = newValue
            }
    }
    
    var petsSection: some View {
        VStack(alignment: .leading) {
            ForEach(["Dogs", "Birds", "Hares", "Fish", "Others"], id: \.self) { pet in
                Stepper("\(pet): \(count(for: pet))", value: binding(for: pet), in: 0...10)
            }
        }
    }
    
    var descriptionSection: some View {
        VStack(alignment: .leading) {
            TextEditor(text: $viewModel.listingDetails.description)
                .frame(height: 100)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray, lineWidth: 1)
                )
            }
        .onTapGesture {
            withAnimation(.snappy) { viewModel.selectedOption = .description }
        }
    }
    
    var locationSection: some View {
        VStack(alignment: .leading) {
            TextField("Enter Location", text: $locationViewModel.location)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            if !locationViewModel.citySuggestions.isEmpty {
                List(locationViewModel.citySuggestions) { city in
                    Text(city.name)
                        .onTapGesture {
                            locationViewModel.location = city.name
                            locationViewModel.fetchCoordinates(for: city)
                            locationViewModel.citySuggestions.removeAll()
                        }
                }
                .frame(height: 100)
            }
        }
    }
    
    var environmentSection: some View {
        Picker("Environment", selection: $viewModel.listingDetails.environment) {
            ForEach(["Beachside", "Countryside", "Forestside", "Urban", "Suburban", "Mountainous", "Lakeside", "Rural", "Coastal", "Desert"], id: \.self) { environment in
                Text(environment).tag(environment)
            }
        }
        .pickerStyle(MenuPickerStyle())
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    var imageSection: some View {
        VStack {
            if !viewModel.listingDetails.images.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(viewModel.listingDetails.images, id: \.self) { image in
                            Image(uiImage: image)
                                .resizable()
                                .frame(width: 100, height: 100)
                                .scaledToFill()
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .padding(4)
                        }
                    }
                }
            }
            
            Button("Choose Listing Images") {
                viewModel.showingImagePicker = true
            }
        }
        .modifier(CollapsibleDestinationViewModifier())
    }
    
    private func count(for pet: String) -> Int {
        switch pet {
        case "Dogs": return viewModel.listingDetails.pets.dogs
        case "Birds": return viewModel.listingDetails.pets.birds
        case "Hares": return viewModel.listingDetails.pets.hares
        case "Fish": return viewModel.listingDetails.pets.fish
        case "Others": return viewModel.listingDetails.pets.others
        default: return 0
        }
    }
    
    private func binding(for pet: String) -> Binding<Int> {
        switch pet {
        case "Dogs": return $viewModel.listingDetails.pets.dogs
        case "Birds": return $viewModel.listingDetails.pets.birds
        case "Hares": return $viewModel.listingDetails.pets.hares
        case "Fish": return $viewModel.listingDetails.pets.fish
        case "Others": return $viewModel.listingDetails.pets.others
        default: return .constant(0)
        }
    }
    
    private func placeholderFor(_ section: ListingSection) -> String {
        switch section {
        case .title: return "Enter Title"
        case .date: return "Choose Date"
        case .pets: return "Number of Pets"
        case .description: return "Write a Description"
        case .location: return "Where's your Location?"
        case .environment: return "Choose an Environment"
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
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding()
            .shadow(radius: 10)
    }
}

struct CollapsedPickerView: View {
    
    let headline: String
    let placeholder: String
    @State private var title = ""
    
    var body: some View {
        VStack(alignment: .leading) {
           HStack {
             Text(headline)
                .foregroundStyle(.gray)
               
               Spacer()
               
               Text(placeholder)
           }
           .fontWeight(.semibold)
           .font(.subheadline)
        }
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



    



