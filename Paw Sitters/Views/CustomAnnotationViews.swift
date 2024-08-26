//
//  CustomAnnotationViews.swift
//  Paw Sitters
//
//  Created by aycan duskun on 18.08.2024.
//

import MapKit

class CustomAnnotationView: MKAnnotationView {
    override var annotation: MKAnnotation? {
        didSet {
            clusteringIdentifier = "customAnnotation" // This enables clustering
            image = UIImage(systemName: "pawprint.fill") // Replace with your image
        }
    }
}


class ClusterAnnotationView: MKAnnotationView {
    private var countLabel: UILabel?

    override var annotation: MKAnnotation? {
        didSet {
            displayPriority = .defaultHigh // Ensures that the cluster annotation is prioritized
            setupClusterView()
        }
    }

    private func setupClusterView() {
        if let clusterAnnotation = annotation as? MKClusterAnnotation {
            // Set the image for the cluster
          //  image = UIImage(systemName: "dog.fill") // Replace with your cluster image
            
            // Remove any existing label
            countLabel?.removeFromSuperview()

            // Add a new label to show the count
            let count = clusterAnnotation.memberAnnotations.count
            let label = UILabel()
            label.text = "\(count)"
            label.textColor = .white
            label.backgroundColor = .red
            label.textAlignment = .center
            label.font = UIFont.boldSystemFont(ofSize: 12)
            label.layer.cornerRadius = 15
            label.clipsToBounds = true

            // Set the size and position of the label
            let size = 30
            label.frame = CGRect(x: self.bounds.width - CGFloat(size / 2), y: self.bounds.height - CGFloat(size / 2), width: CGFloat(size), height: CGFloat(size))

            addSubview(label)
            countLabel = label
        }
    }
}
