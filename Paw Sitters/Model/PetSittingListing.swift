//
//  PetSittingListing.swift
//  Paw Sitters
//
//  Created by aycan duskun on 21.06.2024.
//

import FirebaseFirestore
import Foundation

struct PetSittingListing: Codable, Identifiable {
    var id: String { documentId }
    let documentId: String
    //@DocumentID var id: String?
    var title: String
    var description: String
    var name: String
    var dateRange: ClosedRange<Date>?
    var imageUrl: String?
    var imageUrls: [String]?
    var timestamp: Timestamp
    var role: String
    var location: String?
    var ownerId: String
    var pets: Pets?
    var latitude: Double?
    var longitude: Double?
    var isFavorite: Bool
    var environment: String
    
    init(documentId: String, data: [String : Any]) {
        self.documentId = documentId
        self.title = data["title"] as? String ?? ""
        self.description = data["description"] as? String ?? ""
        self.name = data["name"] as? String ?? ""
        self.imageUrls = data["imageUrls"] as? [String] ?? [""]
        self.timestamp = data["timestamp"] as? Timestamp ?? Timestamp(date: Date())
        self.role = data["role"] as? String ?? ""
        self.location = data["location"] as? String ?? ""
        self.ownerId = data["ownerId"] as? String ?? ""
        // dateRange'i uygun şekilde dönüştürün
        if let dateRangeDict = data["dateRange"] as? [String: Timestamp],
            let startTimestamp = dateRangeDict["start"],
            let endTimestamp = dateRangeDict["end"] {
            self.dateRange = startTimestamp.dateValue()...endTimestamp.dateValue()
        } else {
            self.dateRange = nil
        }
        if let petsData = data["pets"] as? [String: Any] {
            self.pets = Pets(data: petsData) 
            } else {
                self.pets = nil
            }
        self.latitude = data["latitude"] as? Double
        self.longitude = data["longitude"] as? Double
        self.isFavorite = data["isFavorite"] as? Bool ?? false
        self.environment = data["environment"] as? String ?? ""
        }
    }


struct Pets: Codable, Identifiable {
    @DocumentID var id: String?
    var numDogs: String?
    var numCats: String?
    var numHares: String?
    var numBirds: String?
    var numOthers: String?
    
    init(data: [String: Any]) {
            if let dogsInt = data["dogs"] as? Int64 {
                self.numDogs = String(dogsInt)
            } else {
                self.numDogs = nil
            }
            
            if let catsInt = data["cats"] as? Int64 {
                self.numCats = String(catsInt)
            } else {
                self.numCats = nil
            }
            
            if let haresInt = data["hares"] as? Int64 {
                self.numHares = String(haresInt)
            } else {
                self.numHares = nil
            }
            
            if let birdsInt = data["birds"] as? Int64 {
                self.numBirds = String(birdsInt)
            } else {
                self.numBirds = nil
            }
            
            if let othersInt = data["others"] as? Int64 {
                self.numOthers = String(othersInt)
            } else {
                self.numOthers = nil
            }
        }
    }
