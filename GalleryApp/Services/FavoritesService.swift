import Foundation

extension Notification.Name {
    static let favoritesDidChange = Notification.Name("favoritesDidChange")
}

protocol FavoritesServiceProtocol: AnyObject {
    func addToFavorites(_ photo: Photo)
    func removeFromFavorites(_ photo: Photo)
    func isFavorite(_ photo: Photo) -> Bool
    func getFavoriteIds() -> Set<String>
}

final class FavoritesService: FavoritesServiceProtocol {
    private var favorites: Set<String> = []
    private let favoritesKey = "favorite_photos"
    private let userDefaults: UserDefaults
    
    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        loadFavorites()
    }
    
    func addToFavorites(_ photo: Photo) {
        favorites.insert(photo.id)
        saveFavorites()
        NotificationCenter.default.post(
            name: .favoritesDidChange,
            object: nil,
            userInfo: ["photoId": photo.id, "isFavorite": true]
        )
    }
    
    func removeFromFavorites(_ photo: Photo) {
        favorites.remove(photo.id)
        saveFavorites()
        NotificationCenter.default.post(
            name: .favoritesDidChange,
            object: nil,
            userInfo: ["photoId": photo.id, "isFavorite": false]
        )
    }
    
    func isFavorite(_ photo: Photo) -> Bool {
        return favorites.contains(photo.id)
    }
    
    func getFavoriteIds() -> Set<String> {
        return favorites
    }
    
    private func saveFavorites() {
        let favoriteIds = Array(favorites)
        userDefaults.set(favoriteIds, forKey: favoritesKey)
    }
    
    private func loadFavorites() {
        if let favoriteIds = userDefaults.array(forKey: favoritesKey) as? [String] {
            favorites = Set(favoriteIds)
        }
    }
}
