import Foundation

protocol FavoritesServiceProtocol {
    func addToFavorites(_ photo: Photo)
    func removeFromFavorites(_ photo: Photo)
    func isFavorite(_ photo: Photo) -> Bool
    func getAllFavorites() -> [Photo]
    func saveFavorites()
    func loadFavorites()
}

class FavoritesService: FavoritesServiceProtocol {
    static let shared = FavoritesService()
    
    private var favorites: Set<String> = []
    private let favoritesKey = "favorite_photos"
    private let userDefaults = UserDefaults.standard
    private var favoritePhotos: [Photo] = []
    
    private init() {
        loadFavorites()
    }
    
    func addToFavorites(_ photo: Photo) {
        favorites.insert(photo.id)
        if !favoritePhotos.contains(where: { $0.id == photo.id }) {
            favoritePhotos.append(photo)
        }
        saveFavorites()
    }
    
    func removeFromFavorites(_ photo: Photo) {
        favorites.remove(photo.id)
        favoritePhotos.removeAll { $0.id == photo.id }
        saveFavorites()
    }
    
    func isFavorite(_ photo: Photo) -> Bool {
        return favorites.contains(photo.id)
    }
    
    func getAllFavorites() -> [Photo] {
        return favoritePhotos
    }
    
    func saveFavorites() {
        let favoriteIds = Array(favorites)
        userDefaults.set(favoriteIds, forKey: favoritesKey)
        
        // Сохраняем полные данные фотографий
        if let encoded = try? JSONEncoder().encode(favoritePhotos) {
            userDefaults.set(encoded, forKey: "\(favoritesKey)_data")
        }
    }
    
    func loadFavorites() {
        if let favoriteIds = userDefaults.array(forKey: favoritesKey) as? [String] {
            favorites = Set(favoriteIds)
        }
        
        // Загружаем полные данные фотографий
        if let data = userDefaults.data(forKey: "\(favoritesKey)_data"),
           let photos = try? JSONDecoder().decode([Photo].self, from: data) {
            favoritePhotos = photos
        }
    }
}
