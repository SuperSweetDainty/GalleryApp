//
//  ImageCacheService.swift
//  GalleryApp
//
//  Created by Даниил Лапутин on 8.10.25.
//

import UIKit

protocol ImageCacheServiceProtocol {
    func loadImage(from url: String, completion: @escaping (UIImage?) -> Void)
    func clearCache()
}

class ImageCacheService: ImageCacheServiceProtocol {
    static let shared = ImageCacheService()
    
    private let cache = NSCache<NSString, UIImage>()
    private let session = URLSession.shared
    
    private init() {
        cache.countLimit = 100
        cache.totalCostLimit = 50 * 1024 * 1024 // 50 MB
    }
    
    func loadImage(from url: String, completion: @escaping (UIImage?) -> Void) {
        let cacheKey = NSString(string: url)
        
        // Проверяем кэш
        if let cachedImage = cache.object(forKey: cacheKey) {
            completion(cachedImage)
            return
        }
        
        guard let imageURL = URL(string: url) else {
            completion(nil)
            return
        }
        
        session.dataTask(with: imageURL) { [weak self] data, response, error in
            DispatchQueue.main.async {
                guard let data = data,
                      let image = UIImage(data: data),
                      error == nil else {
                    completion(nil)
                    return
                }
                
                // Сохраняем в кэш
                self?.cache.setObject(image, forKey: cacheKey)
                completion(image)
            }
        }.resume()
    }
    
    func clearCache() {
        cache.removeAllObjects()
    }
}
