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
    var onZoomChange: ((Double) -> Void)?
    //var region: MKCoordinateRegion

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.region = region
        mapView.register(MKMarkerAnnotationView.self, forAnnotationViewWithReuseIdentifier: MKMapViewDefaultAnnotationViewReuseIdentifier)
        mapView.register(MKMarkerAnnotationView.self, forAnnotationViewWithReuseIdentifier: MKMapViewDefaultClusterAnnotationViewReuseIdentifier)
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
        return Coordinator(self, onZoomChange: onZoomChange)
    }

    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: MapView
        var onZoomChange: ((Double) -> Void)?

        init(_ parent: MapView, onZoomChange: ((Double) -> Void)?) {
            self.parent = parent
            self.onZoomChange = onZoomChange
        }
        
        func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
            let zoomLevel = mapView.region.span.latitudeDelta
            onZoomChange?(zoomLevel)
        }

        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            if annotation is MKClusterAnnotation {
                let view = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: MKMapViewDefaultClusterAnnotationViewReuseIdentifier)
                view.markerTintColor = .purple
                view.titleVisibility = .visible
                view.canShowCallout = true
                return view
            } else {
                let view = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: MKMapViewDefaultAnnotationViewReuseIdentifier)
                view.markerTintColor = .red
                view.canShowCallout = true
                return view
            }
        }
    }
}
