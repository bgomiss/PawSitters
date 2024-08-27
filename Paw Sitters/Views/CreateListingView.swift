//
//  CreateListingView.swift
//  Paw Sitters
//
//  Created by aycan duskun on 13.07.2024.
//

import SwiftUI
import HorizonCalendar
import FirebaseFirestore

enum ListingDetails {
    case title
    case date
    case pets
    case description
    case location
}

struct CreateListingView: View {
    
    @State private var name: String = ""
    @State private var location: String = ""
    var role: String?
    @State private var description: String = ""
    @State private var title = ""
    @State private var selectedOption: ListingDetails = .title
    @State private var numBirds = 0
    @State private var numHares = 0
    @State private var numFish = 0
    @State private var numDogs = 0
    @State private var numOthers = 0
    @State private var selectedDateRange: ClosedRange<Date>?
    private let calendar = Calendar.current
    private let startDate: Date
    private let endDate: Date
    @State private var images: [UIImage] = []
    @State private var listings = PetSittingListing(documentId: "", data: [:])
    @State private var showingAlert = false
    @State private var showingImagePicker = false
    @State private var isPresenting = false
    @State private var showingDatePicker = false
    @State private var alertMessage = ""
    @State private var alertTitle = ""
    @StateObject private var viewModel = LocationViewModel()
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var firestoreService: FirestoreService
    @EnvironmentObject var storageService: StorageService
    @EnvironmentObject var userProfileService: UserProfileService
    @EnvironmentObject var navigationPathManager: NavigationPathManager
    @Environment(\.presentationMode) var presentationMode
    
    
    init(role: String?) {
        self.startDate = calendar.date(from: DateComponents(year: 2023, month: 01, day: 01))!
        self.endDate = calendar.date(from: DateComponents(year: 2026, month: 12, day: 31))!
        self.role = role
    }
    
    var body: some View {
        VStack {
            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .foregroundStyle(.black)
                .font(.subheadline)
                .fontWeight(.bold)
                
                Spacer()
                
                if !title.isEmpty {
                    Button("Clear") {
                      title = ""
                    }
                    .foregroundStyle(.black)
                    .font(.subheadline)
                    .fontWeight(.bold)
                }
            }
            .padding()
            
           VStack(alignment: .leading) {
                if selectedOption == .title {
                    Text("Title")
                        .font(.title2)
                        .fontWeight(.semibold)
                    HStack {
                        TextField("Enter Title", text: $title)
                            .font(.subheadline)
                    }
                    .frame(height: 44)
                    .padding(.horizontal)
                    .overlay {
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(lineWidth: 1.0)
                            .foregroundStyle(Color(.systemGray4))
                    }
                } else {
                    CollapsedPickerView(headline: "Title", placeholder: "Enter Title")
                }
            }
           .modifier(CollapsibleDestinationViewModifier())
           .frame(height: selectedOption == .title ? 120 : 64)
            .onTapGesture {
                withAnimation(.snappy) { selectedOption = .title }
            }
            
            VStack {
                if selectedOption == .date {
                    HorizonCalendar(calendar: calendar, monthsLayout: .vertical, selectedDateRange: $selectedDateRange)
                } else {
                    CollapsedPickerView(headline: "When", placeholder: "Add Dates")
                }
            }
            .modifier(CollapsibleDestinationViewModifier())
            .frame(height: selectedOption == .date ? 300 : 64)
            .onTapGesture {
                withAnimation(.snappy) { selectedOption = .date }
            }
            
        VStack(alignment: .leading) {
                if selectedOption == .pets {
                   Text("What are the pets?")
                        .font(.title)
                        .fontWeight(.semibold)
                    Stepper {
                        HStack {
                            Image(systemName: "dog.fill")
                            Text("\(numDogs)")
                        }
                    } onIncrement: {
                        numDogs += 1
                    } onDecrement: {
                        guard numDogs > 0 else { return }
                        numDogs -= 1                    }
                    
                    Stepper {
                        HStack {
                            Image(systemName: "bird.fill")
                            Text("\(numBirds)")
                        }
                    } onIncrement: {
                        numBirds += 1
                    } onDecrement: {
                        guard numBirds > 0 else { return }
                        numBirds -= 1                    }
                    
                    Stepper {
                        HStack {
                            Image(systemName: "hare.fill")
                            Text("\(numHares)")
                        }
                    } onIncrement: {
                        numHares += 1
                    } onDecrement: {
                        guard numHares > 0 else { return }
                        numHares -= 1                    }
                    Stepper {
                        HStack {
                            Image(systemName: "fish.fill")
                            Text("\(numFish)")
                        }
                    } onIncrement: {
                        numFish += 1
                    } onDecrement: {
                        guard numFish > 0 else { return }
                        numFish -= 1                    }
                    
                    Stepper {
                        HStack {
                            Image(systemName: "pawprint.fill")
                            Text("\(numOthers)")
                        }
                    } onIncrement: {
                        numOthers += 1
                    } onDecrement: {
                        guard numOthers > 0 else { return }
                        numOthers -= 1                    }
                    
                } else {
                    CollapsedPickerView(headline: "Pets", placeholder: "Choose the pets")
                }
            }
            .modifier(CollapsibleDestinationViewModifier())
            .frame(height: selectedOption == .pets ? 200 : 64)
            .padding(EdgeInsets(top: selectedOption == .pets ? 40 : 0, leading: 0, bottom: selectedOption == .pets ? 40 : 0, trailing: 0))
            .onTapGesture {
                withAnimation { selectedOption = .pets }
            }
            
            VStack(alignment: .leading) {
                if selectedOption == .description {
                    ZStack(alignment: .topLeading) {
                        if description.isEmpty {
                            Text("Enter a description")
                                .foregroundColor(.gray)
                                .padding(.top, 8)
                                .padding(.horizontal, 4)
                        }
                        TextEditor(text: $description)
                            .frame(height: 150)
                            .onChange(of: description) {_, newValue in
                                if newValue.count > 150 {
                                    description = String(newValue.prefix(150))
                             }
                        }
                    }
                } else {
                    CollapsedPickerView(headline: "Description", placeholder: "Enter Description")
                }
            }
            .modifier(CollapsibleDestinationViewModifier())
            .frame(height: selectedOption == .description ? 180 : 64)
            .onTapGesture {
                withAnimation { selectedOption = .description }
            }
            
            VStack(alignment: .leading) {
                 if selectedOption == .location {
                     Text("Location")
                         .font(.title2)
                         .fontWeight(.semibold)
                     HStack {
                         TextField("Choose your location", text: $viewModel.location)
                             .font(.subheadline)
                     }
                     .frame(height: 44)
                     .padding(.horizontal)
                     .overlay {
                         RoundedRectangle(cornerRadius: 8)
                             .stroke(lineWidth: 1.0)
                             .foregroundStyle(Color(.systemGray4))
                     }
                     if !viewModel.citySuggestions.isEmpty {
                             List(viewModel.citySuggestions) { city in
                                 Text(city.name)
                                     .onTapGesture {
                                         viewModel.location = city.name
                                         viewModel.fetchCoordinates(for: city)
                                         viewModel.citySuggestions = []                                     }
                             }
                             // .frame(height: 100)
                         }
                 } else {
                     CollapsedPickerView(headline: "Location", placeholder: "Choose the Location")
                 }
             }
            .modifier(CollapsibleDestinationViewModifier())
            .frame(height: selectedOption == .location ? 280 : 64)
            .padding(.bottom)
             .onTapGesture {
                 withAnimation(.snappy) { selectedOption = .location }
             }
            
            if !images.isEmpty {
                ScrollView(.horizontal) {
                    HStack {
                        ForEach(images, id: \.self) { image in
                            Image(uiImage: image)
                                .resizable()
                                .frame(width: 100, height: 100)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .padding(4)
                        }
                    }
                }
            }
            
            Button("Choose Listing Images ") {
                showingImagePicker = true
            }
            .padding(.bottom, 18)
            
            Button("Publish") {
                uploadImagesAndPublishListing()
            }
            
            .alert(isPresented: $showingAlert) {
                Alert(
                    title: Text(alertTitle),
                    message: Text(alertMessage),
                    dismissButton: .default(Text("OK")) {
                        presentationMode.wrappedValue.dismiss()
                    }
                )
            }
            
            .navigationBarItems(leading: Text("Please Enter The Details Below")
                .font(.custom("HelveticaNeue-Thin", size: 16))
                .foregroundColor(.teal)
                .fontWeight(.bold)
            )
            .navigationBarItems(trailing: Button("Cancel") {
                presentationMode.wrappedValue.dismiss()
            })
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(images: $images)
            }
            Spacer()
        }
        
    }
    

private func uploadImagesAndPublishListing() {
    var imageUrls: [String] = []
    let dispatchGroup = DispatchGroup()
    
    for image in images {
        dispatchGroup.enter()
        storageService.uploadImage(image, path: "listing_images/\(UUID().uuidString).jpg") { result in
            switch result {
            case .success(let imageUrl):
                imageUrls.append(imageUrl)
            case .failure(let error):
                print("Error uploading image: \(error.localizedDescription)")
            }
            dispatchGroup.leave()
        }
    }
    
    dispatchGroup.notify(queue: .main) {
        self.publishListing(imageUrls: imageUrls)
    }
}

private func publishListing(imageUrls: [String]) {
    let ownerId = authService.user?.uid ?? ""
    let pets = [
            "birds": numBirds,
            "dogs": numDogs,
            "hares": numHares,
            "fish": numFish,
            "others": numOthers
    ] as [String : Any]
    // selectedDateRange'i uygun bir formata dönüştürün
        let dateRangeDict: [String: Any]?
        if let dateRange = selectedDateRange {
            dateRangeDict = [
                "start": Timestamp(date: dateRange.lowerBound),
                "end": Timestamp(date: dateRange.upperBound)
            ]
        } else {
            dateRangeDict = nil
        }
    
    let listingData = [
        "title": title,
        "description": description,
        "name": name,
        "timestamp": Timestamp(date: Date()),
        "dateRange": dateRangeDict as Any,
        "imageUrls": imageUrls,
        "role": role ?? "Sitter",
        "ownerId": ownerId,
        "location": viewModel.location,
        "latitude": viewModel.selectedCityCoordinates?.latitude as Any,
        "longitude": viewModel.selectedCityCoordinates?.longitude as Any,
        "pets": pets
    ] as [String : Any]

    
    firestoreService.addListing(role ?? "Sitter", listingData: listingData) { result in
        switch result {
        case .success():
            alertTitle = "Success"
            alertMessage = "Listing published successfully"
            showingAlert = true
            print("SAVED SUCCESSFULLY")
        case .failure(let error):
            alertTitle = "Error"
            alertMessage = error.localizedDescription
            showingAlert = true
            print(alertMessage)
         }
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
//        NavigationView {
//            Form {
//                Section(header: Text("Please Enter The Details Below")) {
//                    
//                    TextField("Title", text: $title)
//                    
//                    TextField("Name&Surname", text: $name)
//                    
//                    // Select Dates section
//                    Section {
//                        Button("Select Dates") {
//                            showingDatePicker.toggle()
//                        }
//                        if let startDate = startDate, let endDate = endDate {
//                            Text("Selected Dates: \(formattedDateRange(startDate: startDate, endDate:endDate))")
//                        }
//                    }
//                    TextField("Location", text: $location)
//                    }
//
//                }
//            }
//        }
//    private func formattedDateRange(startDate: Date, endDate: Date) -> String {
//            let formatter = DateFormatter()
//            formatter.dateFormat = "dd MMM yyyy"
//            return "\(formatter.string(from: startDate)) - \(formatter.string(from: endDate))"
//        }
    



