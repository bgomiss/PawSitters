//
//  StorageService.swift
//  Paw Sitters
//
//  Created by aycan duskun on 21.06.2024.
//

import UIKit
import FirebaseStorage

class StorageService: ObservableObject {
    private var storage = Storage.storage()
    
    func uploadImage(_ image: UIImage, path: String, completion: @escaping (Result<String, Error>) -> Void) {
        let storageRef = storage.reference().child(path)
        
        if let imageData = image.jpegData(compressionQuality: 0.8) {
            storageRef.putData(imageData, metadata: nil) { metadata, error in
                if let error = error {
                    completion(.failure(error))
                } else {
                    storageRef.downloadURL { url, error in
                        if let error = error {
                            completion(.failure(error))
                        } else if let url = url {
                            completion(.success(url.absoluteString))
                        }
                    }
                }
            }
        } else {
            completion(.failure(NSError(domain: "Invalid image data", code: -1, userInfo: nil)))
        }
    }
}


