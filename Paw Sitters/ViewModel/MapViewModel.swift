//
//  MapViewModel.swift
//  Paw Sitters
//
//  Created by aycan duskun on 14.08.2024.
//

import SwiftUI
import MapKit

class MapViewModel: ObservableObject {
    @Published var annotations: [MKPointAnnotation] = []

    func createAnnotations(from listings: [PetSittingListing], zoomLevel: Double) {
        let group = DispatchGroup()
        var temporaryAnnotations: [MKPointAnnotation] = []

        for listing in listings {
            group.enter()
            if let latitude = listing.latitude, let longitude = listing.longitude {
                let annotation = MKPointAnnotation()
                annotation.title = listing.title
                annotation.coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
                temporaryAnnotations.append(annotation)
                group.leave()
            } else if let locationName = listing.location {
                let searchRequest = MKLocalSearch.Request()
                searchRequest.naturalLanguageQuery = locationName
                
                let search = MKLocalSearch(request: searchRequest)
                search.start { response, error in
                    if let error = error {
                        print("Error searching for location: \(error.localizedDescription)")
                        group.leave()
                        return
                    }
                    
                    if let coordinate = response?.mapItems.first?.placemark.coordinate {
                        let annotation = MKPointAnnotation()
                        annotation.title = listing.title
                        annotation.coordinate = coordinate
                        temporaryAnnotations.append(annotation)
                    }
                    group.leave()
                }
            } else {
                group.leave()
            }
        }

        group.notify(queue: .main) {
            self.annotations = temporaryAnnotations
        }
    }
}
