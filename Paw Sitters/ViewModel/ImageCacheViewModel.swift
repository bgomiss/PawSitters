//
//  ImageCacheViewModel.swift
//  Paw Sitters
//
//  Created by aycan duskun on 31.08.2024.
//
import SwiftUI

class ImageCacheViewModel: ObservableObject {
    @Published var images: [String: UIImage] = [:]
    
    func loadImage(from url: URL, for key: String) {
        // Check if the image is already cached
        if images[key] != nil {
            return
        }
        
        // Otherwise, load the image from the URL
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let data = data, let uiImage = UIImage(data: data) {
                DispatchQueue.main.async {
                    self.images[key] = uiImage
                }
            }
        }.resume()
    }
}

