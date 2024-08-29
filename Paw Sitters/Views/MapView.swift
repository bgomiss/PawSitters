//
//  MapView.swift
//  Paw Sitters
//
//  Created by aycan duskun on 14.08.2024.
//

import MapKit
import SwiftUI

struct MapView: UIViewRepresentable {
    @Binding var annotations: [MKPointAnnotation]
    @Binding var region: MKCoordinateRegion
    @ObservedObject var firestoreService: FirestoreService
    var onZoomChange: ((Double) -> Void)?
    var onAnnotationSelect: ((PetSittingListing) -> Void)?

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.region = region
        mapView.register(CustomAnnotationView.self, forAnnotationViewWithReuseIdentifier: MKMapViewDefaultAnnotationViewReuseIdentifier)
        mapView.register(ClusterAnnotationView.self, forAnnotationViewWithReuseIdentifier: MKMapViewDefaultClusterAnnotationViewReuseIdentifier)
        mapView.showsUserLocation = true
        mapView.isZoomEnabled = true
        mapView.isScrollEnabled = true
        mapView.isPitchEnabled = true
        mapView.isRotateEnabled = true
        mapView.addAnnotations(annotations)
        return mapView
    }

    func updateUIView(_ mapView: MKMapView, context: Context) {
        mapView.removeAnnotations(mapView.annotations)
        mapView.addAnnotations(annotations)
    }

    func makeCoordinator() -> Coordinator {
        return Coordinator(self, onZoomChange: onZoomChange, onAnnotationSelect: onAnnotationSelect, fireStoreService: firestoreService)
    }

    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: MapView
        var onZoomChange: ((Double) -> Void)?
        var onAnnotationSelect: ((PetSittingListing) -> Void)?
        @ObservedObject var firestoreService: FirestoreService

        init(_ parent: MapView, onZoomChange: ((Double) -> Void)?, onAnnotationSelect: ((PetSittingListing) -> Void)?, fireStoreService: FirestoreService) {
            self.parent = parent
            self.onZoomChange = onZoomChange
            self.onAnnotationSelect = onAnnotationSelect
            self.firestoreService = fireStoreService
        }
        
        func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
            let zoomLevel = mapView.region.span.latitudeDelta
            onZoomChange?(zoomLevel)
        }

        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            if let clusterAnnotation = annotation as? MKClusterAnnotation {
                let view = mapView.dequeueReusableAnnotationView(withIdentifier: MKMapViewDefaultClusterAnnotationViewReuseIdentifier, for: clusterAnnotation) as! ClusterAnnotationView
                view.annotation = clusterAnnotation
                return view
            } else {
                let view = mapView.dequeueReusableAnnotationView(withIdentifier: MKMapViewDefaultAnnotationViewReuseIdentifier, for: annotation) as! CustomAnnotationView
                view.annotation = annotation
                view.canShowCallout = true
                return view
            }
        }
        
        func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
            if let annotation = view.annotation as? MKPointAnnotation {
                    // Listing'i bulun ve seçili listing olarak ayarlayın
                    if let selectedListing = firestoreService.listings.first(where: { $0.title == annotation.title }) {
                        parent.onAnnotationSelect?(selectedListing)
                    }
                }
        }

    }
}
