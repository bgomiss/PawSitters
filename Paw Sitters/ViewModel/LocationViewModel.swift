//
//  LocationViewModel.swift
//  Paw Sitters
//
//  Created by aycan duskun on 29.07.2024.
//

import Combine
import MapKit
import SwiftUI

class LocationViewModel: NSObject, ObservableObject {
    @Published var location: String = ""
    @Published var citySuggestions: [City] = []
    @Published var selectedCityCoordinates: CLLocationCoordinate2D? // To store the selected city's coordinates

    private var completer = MKLocalSearchCompleter()
    private var cancellables = Set<AnyCancellable>()

    override init() {
        super.init()
        completer.resultTypes = .address
        completer.delegate = self

        $location
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { [weak self] value in
                self?.completer.queryFragment = value
            }
            .store(in: &cancellables)
    }

    // Function to search for the coordinates of the selected city
    func fetchCoordinates(for city: City) {
        let searchRequest = MKLocalSearch.Request()
        searchRequest.naturalLanguageQuery = city.name
        
        let search = MKLocalSearch(request: searchRequest)
        search.start { [weak self] response, error in
            if let error = error {
                print("Error fetching coordinates: \(error.localizedDescription)")
                return
            }
            
            if let coordinate = response?.mapItems.first?.placemark.coordinate {
                self?.selectedCityCoordinates = coordinate
            }
        }
    }
}

extension LocationViewModel: MKLocalSearchCompleterDelegate {
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        self.citySuggestions = completer.results.map { City(name: $0.title) }
    }

    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        print("Error: \(error.localizedDescription)")
    }
}
