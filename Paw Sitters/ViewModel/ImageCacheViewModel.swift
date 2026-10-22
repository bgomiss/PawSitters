//
//  ImageCacheViewModel.swift
//  Paw Sitters
//
//  Created by aycan duskun on 31.08.2024.
//
import SwiftUI

/// Main-actor isolated so the download tasks below never touch
/// `loadingTasks` / `images` from several threads at once.
@MainActor
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
            images[urlString] = cachedImage
            return
        }
        
        // Already downloading this URL
        if loadingTasks[urlString] != nil { return }
        
        // Create new task
        let task = Task {
            guard let url = URL(string: urlString) else { return }
            
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                if let image = UIImage(data: data) {
                    cache.setObject(image, forKey: urlString as NSString)
                    images[urlString] = image
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

