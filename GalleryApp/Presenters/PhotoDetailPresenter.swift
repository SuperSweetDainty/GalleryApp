import Foundation

protocol PhotoDetailViewProtocol: AnyObject {
    func displayPhoto(_ photo: Photo)
    func showError(_ error: Error)
    func updateFavoriteButton(isFavorite: Bool)
}

protocol PhotoDetailPresenterProtocol: AnyObject {
    var view: PhotoDetailViewProtocol? { get set }
    func loadPhoto()
    func toggleFavorite()
    func getCurrentPhoto() -> Photo
    func isFavorite(_ photo: Photo) -> Bool
    func canNavigateToNext() -> Bool
    func canNavigateToPrevious() -> Bool
    func navigateToNext()
    func navigateToPrevious()
}

final class PhotoDetailPresenter: PhotoDetailPresenterProtocol {
    weak var view: PhotoDetailViewProtocol?
    
    private let favoritesService: FavoritesServiceProtocol
    private let photos: [Photo]
    private var currentIndex: Int
    
    init(photos: [Photo],
         currentIndex: Int,
         favoritesService: FavoritesServiceProtocol) {
        self.photos = photos
        self.currentIndex = currentIndex
        self.favoritesService = favoritesService
    }
    
    func loadPhoto() {
        let photo = photos[currentIndex]
        view?.displayPhoto(photo)
        view?.updateFavoriteButton(isFavorite: favoritesService.isFavorite(photo))
    }
    
    func toggleFavorite() {
        let photo = photos[currentIndex]
        if favoritesService.isFavorite(photo) {
            favoritesService.removeFromFavorites(photo)
        } else {
            favoritesService.addToFavorites(photo)
        }
        
        view?.updateFavoriteButton(isFavorite: favoritesService.isFavorite(photo))
    }
    
    func getCurrentPhoto() -> Photo {
        return photos[currentIndex]
    }
    
    func isFavorite(_ photo: Photo) -> Bool {
        return favoritesService.isFavorite(photo)
    }
    
    func canNavigateToNext() -> Bool {
        return currentIndex < photos.count - 1
    }
    
    func canNavigateToPrevious() -> Bool {
        return currentIndex > 0
    }
    
    func navigateToNext() {
        guard canNavigateToNext() else { return }
        currentIndex += 1
        loadPhoto()
    }
    
    func navigateToPrevious() {
        guard canNavigateToPrevious() else { return }
        currentIndex -= 1
        loadPhoto()
    }
}
