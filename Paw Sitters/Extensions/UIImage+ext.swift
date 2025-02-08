//
//  UIImage+ext.swift
//  Paw Sitters
//
//  Created by aycan duskun on 21.06.2024.
//

import UIKit

extension UIImage {
    func resized(to size: CGSize) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        self.draw(in: CGRect(origin: .zero, size: size))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return resizedImage
    }
    
    // Add compression method
    func compressed() -> UIImage? {
        guard let data = self.jpegData(compressionQuality: 0.5) else { return nil }
        return UIImage(data: data)
    }
    
    // Add aspect ratio resize
    func resizedToAspectRatio(width: CGFloat) -> UIImage? {
        let aspectRatio = size.width / size.height
        let newSize = CGSize(width: width, height: width / aspectRatio)
        return resized(to: newSize)
    }
}

