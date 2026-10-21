//
//  ImageCacheViewModel.swift
//  Paw Sitters
//
//  Created by aycan duskun on 31.08.2024.
//
import SwiftUI

class ImageCacheViewModel: ObservableObject {
    private let cache = NSCache<NSString, UIImage>()
    private var loadingTasks: [String: Task<Void, Never>] = [:]
    @Published var images: [String: UIImage] = [:]
    
    init() {
        cache.countLimit = 100 // Cache up to 100 images
    }
    
    func loadImage(from urlString: String) {
        // Return if image is already in memory
        if images[urlString] != nil { return }
        
        // Check cache first
        if let cachedImage = cache.object(forKey: urlString as NSString) {
            DispatchQueue.main.async {
                self.images[urlString] = cachedImage
            }
            return
        }
        
        // Cancel any existing task for this URL
        loadingTasks[urlString]?.cancel()
        
        // Create new task
        let task = Task {
            guard let url = URL(string: urlString) else { return }
            
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                if let image = UIImage(data: data) {
                    DispatchQueue.main.async {
                        self.cache.setObject(image, forKey: urlString as NSString)
                        self.images[urlString] = image
                    }
                }
            } catch {
                print("Failed to load image: \(error)")
            }
            
            loadingTasks[urlString] = nil
        }
        
        loadingTasks[urlString] = task
    }
    
    func clearCache() {
        cache.removeAllObjects()
        images.removeAll()
        loadingTasks.values.forEach { $0.cancel() }
        loadingTasks.removeAll()
    }
}

