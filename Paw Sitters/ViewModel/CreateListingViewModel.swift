//
//  CreateListingViewModel.swift
//  Paw Sitters
//
//  Created by aycan duskun on 5.10.2024.
//
import SwiftUI
import FirebaseFirestore

class CreateListingViewModel: ObservableObject {
    @Published var listingDetails = ListingDetails()
    @Published var selectedOption: ListingSection = .title
    @Published var showingImagePicker = false
    @Published var showingAlert = false
    @Published var alertTitle = ""
    @Published var alertMessage = ""
    @Published var isPublishing = false
    
    var locationViewModel: LocationViewModel
    
    init(locationViewModel: LocationViewModel) {
        self.locationViewModel = locationViewModel
    }
    
    func reset() {
        listingDetails = ListingDetails()
        selectedOption = .title
        locationViewModel.location = ""
        locationViewModel.selectedCityCoordinates = nil
    }
    
    func publishListing(role: String, ownerName: String, authService: AuthService, firestoreService: FirestoreService, storageService: StorageService) {
        guard let ownerId = authService.user?.uid else {
            showAlert(title: "Error", message: "You need to be signed in to publish a listing.")
            return
        }
        guard !listingDetails.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            showAlert(title: "Missing Title", message: "Please enter a title for your listing.")
            return
        }
        isPublishing = true
        let pets = [
            "birds": listingDetails.pets.birds,
            "dogs": listingDetails.pets.dogs,
            "cats": listingDetails.pets.cats,
            "hares": listingDetails.pets.hares,
            "fish": listingDetails.pets.fish,
            "others": listingDetails.pets.others
        ] as [String : Any]
        
        let dateRangeDict: [String: Any]?
        if let dateRange = listingDetails.dateRange {
            dateRangeDict = [
                "start": Timestamp(date: dateRange.lowerBound),
                "end": Timestamp(date: dateRange.upperBound)
            ]
        } else {
            dateRangeDict = nil
        }
        
        var imageUrls: [String] = []
        let dispatchGroup = DispatchGroup()
        
        for image in listingDetails.images {
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
            let listingData = [
                "title": self.listingDetails.title,
                "description": self.listingDetails.description,
                "timestamp": Timestamp(date: Date()),
                "dateRange": dateRangeDict as Any,
                "imageUrls": imageUrls,
                "role": role,
                "name": ownerName,
                "ownerId": ownerId,
                "location": self.locationViewModel.location,
                "latitude": self.locationViewModel.selectedCityCoordinates?.latitude as Any,
                "longitude": self.locationViewModel.selectedCityCoordinates?.longitude as Any,
                "environment": self.listingDetails.environment,
                "pets": pets
            ] as [String : Any]
            
            firestoreService.addListing(role, listingData: listingData) { result in
                self.isPublishing = false
                switch result {
                case .success():
                    self.showAlert(title: "Success", message: "Listing published successfully")
                case .failure(let error):
                    self.showAlert(title: "Error", message: error.localizedDescription)
                }
            }
        }
    }
}

extension CreateListingViewModel {
    func showAlert(title: String, message: String) {
        alertTitle = title
        alertMessage = message
        showingAlert = true
    }
}

struct ListingDetails {
    var title = ""
    var dateRange: ClosedRange<Date>?
    var pets = PetCount()
    var description = ""
    var environment = ""
    var images: [UIImage] = []
}

struct PetCount {
    var dogs = 0
    var cats = 0
    var birds = 0
    var hares = 0
    var fish = 0
    var others = 0
}

enum ListingSection: String, CaseIterable {
    case title = "Title"
    case date = "Date"
    case pets = "Pets"
    case description = "Description"
    case location = "Location"
    case environment = "Environment"
}
