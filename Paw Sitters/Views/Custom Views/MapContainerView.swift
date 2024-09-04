//
//  MapContainerView.swift
//  Paw Sitters
//
//  Created by aycan duskun on 14.08.2024.
//

import SwiftUI
import MapKit

struct MapContainerView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var annotations: [MKPointAnnotation]
    @Binding var region: MKCoordinateRegion
    @StateObject private var viewModel = MapViewModel()
    @ObservedObject var firestoreService: FirestoreService
    @State private var selectedListing: PetSittingListing?
    @State private var zoomLevel: Double = 0.0
    let heights = stride(from: 0.1, through: 1.0, by: 0.1).map { PresentationDetent.fraction($0) }
    
    var listings: [PetSittingListing]
    
    var body: some View {
            ZStack {
                // MARK: - Map View
                MapView(
                    annotations: $viewModel.annotations,
                    region: $region,
                    firestoreService: firestoreService,
                    onZoomChange: { newZoomLevel in
                        zoomLevel = newZoomLevel
                        viewModel.createAnnotations(from: listings, zoomLevel: newZoomLevel)
                    }, onAnnotationSelect: { listing in
                        selectedListing = listing
                    }
                )
                .ignoresSafeArea()
                
                // MARK: - Top Controls
                VStack {
                    HStack {
                        Button(action: {
                            dismiss()
                        }) {
                            Image(systemName: "chevron.left")
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.black.opacity(0.6))
                                .clipShape(Circle())
                        }
                        Spacer()
                        Text(String(format: "Zoom Level: %.2f", zoomLevel))
                            .foregroundColor(.white)
                            .padding(8)
                            .background(Color.black.opacity(0.6))
                            .cornerRadius(8)
                    }
                    .padding(.horizontal)
                    .padding(.top, 50) // Adjust according to safe area

                    Spacer()
                }

                // MARK: - Bottom Sheet View
                .sheet(item: $selectedListing) { listing in
                    BottomSheetView(listing: listing)
                        .presentationDetents(Set(heights))
                        .presentationDragIndicator(.hidden)
                }
            }
            .onAppear {
                viewModel.createAnnotations(from: listings, zoomLevel: region.span.latitudeDelta)
            }
        }
    }
//struct MapContainerView_Previews: PreviewProvider {
//    static var previews: some View {
//        MapContainerView(
//            annotations: .constant(sampleAnnotations()),
//            $region: MKCoordinateRegion(
//                center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
//                span: MKCoordinateSpan(latitudeDelta: 10, longitudeDelta: 10)
//            )
//        )
//    }
//    
//    static func sampleAnnotations() -> [MKPointAnnotation] {
//        var annotations: [MKPointAnnotation] = []
//        
//        let annotation1 = MKPointAnnotation()
//        annotation1.title = "San Francisco"
//        annotation1.coordinate = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
//        annotations.append(annotation1)
//        
//        let annotation2 = MKPointAnnotation()
//        annotation2.title = "Los Angeles"
//        annotation2.coordinate = CLLocationCoordinate2D(latitude: 34.0522, longitude: -118.2437)
//        annotations.append(annotation2)
//        
//        return annotations
//    }
//}
