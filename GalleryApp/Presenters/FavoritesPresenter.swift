import Foundation

protocol FavoritesViewProtocol: AnyObject {
    func displayFavorites(_ photos: [Photo])
    func showError(_ error: Error)
}

protocol FavoritesPresenterProtocol: AnyObject {
    var view: FavoritesViewProtocol? { get set }
    func loadFavorites()
    func removeFavorite(_ photo: Photo)
    func isFavorite(_ photo: Photo) -> Bool
}

final class FavoritesPresenter: FavoritesPresenterProtocol {
    weak var view: FavoritesViewProtocol?
    
    private let networkService: NetworkServiceProtocol
    private let favoritesService: FavoritesServiceProtocol
    private var allPhotos: [Photo] = []
    
    init(networkService: NetworkServiceProtocol,
         favoritesService: FavoritesServiceProtocol) {
        self.networkService = networkService
        self.favoritesService = favoritesService
    }
    
    func loadFavorites() {
        networkService.fetchPhotos(page: 1) { [weak self] result in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                switch result {
                case .success(let photoResponse):
                    self.allPhotos = photoResponse.results
                    self.filterAndDisplayFavorites()
                    
                case .failure(let error):
                    self.view?.showError(error)
                }
            }
        }
    }
    
    func removeFavorite(_ photo: Photo) {
        favoritesService.removeFromFavorites(photo)
    }
    
    func isFavorite(_ photo: Photo) -> Bool {
        return favoritesService.isFavorite(photo)
    }
    
    private func filterAndDisplayFavorites() {
        let favoriteIds = favoritesService.getFavoriteIds()
        let favoritePhotos = allPhotos.filter { favoriteIds.contains($0.id) }
        view?.displayFavorites(favoritePhotos)
    }
}

