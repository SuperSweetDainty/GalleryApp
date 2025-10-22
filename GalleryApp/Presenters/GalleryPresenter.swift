import Foundation

protocol GalleryViewProtocol: AnyObject {
    func displayPhotos(_ photos: [Photo])
    func showError(_ error: Error)
    func showLoading(_ isLoading: Bool)
}

protocol GalleryPresenterProtocol: AnyObject {
    var view: GalleryViewProtocol? { get set }
    func loadPhotos()
    func loadMorePhotos()
    func toggleFavorite(for photo: Photo)
    func isFavorite(_ photo: Photo) -> Bool
}

final class GalleryPresenter: GalleryPresenterProtocol {
    weak var view: GalleryViewProtocol?
    
    private let networkService: NetworkServiceProtocol
    private let favoritesService: FavoritesServiceProtocol
    
    private var currentPage = 1
    private var isLoading = false
    private var hasMorePages = true
    private var allPhotos: [Photo] = []
    
    init(networkService: NetworkServiceProtocol,
         favoritesService: FavoritesServiceProtocol) {
        self.networkService = networkService
        self.favoritesService = favoritesService
    }
    
    func loadPhotos() {
        guard !isLoading else { return }
        
        currentPage = 1
        allPhotos = []
        hasMorePages = true
        
        loadPhotosPage(page: currentPage)
    }
    
    func loadMorePhotos() {
        guard !isLoading && hasMorePages else { return }
        
        currentPage += 1
        loadPhotosPage(page: currentPage)
    }
    
    private func loadPhotosPage(page: Int) {
        isLoading = true
        view?.showLoading(true)
        
        networkService.fetchPhotos(page: page) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                self?.view?.showLoading(false)
                
                switch result {
                case .success(let photoResponse):
                    if page == 1 {
                        self?.allPhotos = photoResponse.results
                    } else {
                        self?.allPhotos.append(contentsOf: photoResponse.results)
                    }
                    
                    self?.hasMorePages = page < photoResponse.totalPages
                    self?.view?.displayPhotos(self?.allPhotos ?? [])
                    
                case .failure(let error):
                    self?.view?.showError(error)
                }
            }
        }
    }
    
    func toggleFavorite(for photo: Photo) {
        if favoritesService.isFavorite(photo) {
            favoritesService.removeFromFavorites(photo)
        } else {
            favoritesService.addToFavorites(photo)
        }
    }
    
    func isFavorite(_ photo: Photo) -> Bool {
        return favoritesService.isFavorite(photo)
    }
}
