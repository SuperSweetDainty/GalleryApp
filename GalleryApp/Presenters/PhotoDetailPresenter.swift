//
//  PhotoDetailPresenter.swift
//  GalleryApp
//
//  Created by Даниил Лапутин on 8.10.25.
//

import Foundation
import UIKit

protocol PhotoDetailViewProtocol: AnyObject {
    func displayPhoto(_ photo: Photo)
    func showError(_ error: Error)
    func updateFavoriteButton(isFavorite: Bool)
    func showLoading(_ isLoading: Bool)
}

protocol PhotoDetailPresenterProtocol {
    var view: PhotoDetailViewProtocol? { get set }
    func loadPhoto()
    func toggleFavorite()
    func getCurrentPhoto() -> Photo?
}

class PhotoDetailPresenter: PhotoDetailPresenterProtocol {
    weak var view: PhotoDetailViewProtocol?
    
    private let favoritesService: FavoritesServiceProtocol
    private let imageCacheService: ImageCacheServiceProtocol
    private var photo: Photo
    
    init(photo: Photo,
         favoritesService: FavoritesServiceProtocol = FavoritesService.shared,
         imageCacheService: ImageCacheServiceProtocol = ImageCacheService.shared) {
        self.photo = photo
        self.favoritesService = favoritesService
        self.imageCacheService = imageCacheService
    }
    
    func loadPhoto() {
        view?.displayPhoto(photo)
        view?.updateFavoriteButton(isFavorite: favoritesService.isFavorite(photo))
    }
    
    func toggleFavorite() {
        if favoritesService.isFavorite(photo) {
            favoritesService.removeFromFavorites(photo)
        } else {
            favoritesService.addToFavorites(photo)
        }
        
        view?.updateFavoriteButton(isFavorite: favoritesService.isFavorite(photo))
    }
    
    func getCurrentPhoto() -> Photo? {
        return photo
    }
}
