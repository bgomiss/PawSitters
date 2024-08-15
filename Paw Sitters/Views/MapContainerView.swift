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
    
    @State private var zoomLevel: Double = 0.0
    
    var listings: [PetSittingListing]
    
    var body: some View {
        VStack {
            HStack {
                Image(systemName: "chevron.left")
                    .onTapGesture {
                        dismiss()
                    }
                //  Text("Back")
                Spacer()
                Text(String(format: "Zoom Seviyesi: %.5f", zoomLevel))
                    .font(.headline)
                    .padding()
                    .background(Color.white)
                    .cornerRadius(8)
                    .shadow(radius: 2)
            }
            .padding()
            .foregroundColor(.blue)
            .cornerRadius(8)
            
            Spacer()
            
            MapView(annotations: $annotations, region: $region, onZoomChange: { newZoomLevel in
                zoomLevel = newZoomLevel
                viewModel.createAnnotations(from: listings, zoomLevel: newZoomLevel)
            })
            .ignoresSafeArea(.all)
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
