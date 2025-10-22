import UIKit

protocol ImageCacheServiceProtocol: AnyObject {
    func loadImage(from url: String, completion: @escaping (UIImage?) -> Void)
}

final class ImageCacheService: ImageCacheServiceProtocol {
    private let cache = NSCache<NSString, UIImage>()
    private let session: URLSession
    
    init(session: URLSession = .shared) {
        self.session = session
        cache.countLimit = 100
        cache.totalCostLimit = 50 * 1024 * 1024
    }
    
    func loadImage(from url: String, completion: @escaping (UIImage?) -> Void) {
        let cacheKey = NSString(string: url)
        
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
                
                self?.cache.setObject(image, forKey: cacheKey)
                completion(image)
            }
        }.resume()
    }
}
