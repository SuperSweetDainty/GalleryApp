import UIKit

final class FavoritesViewController: UIViewController {
    
    // MARK: - Properties
    private var presenter: FavoritesPresenterProtocol!
    private var photos: [Photo] = []
    private let favoritesService: FavoritesServiceProtocol
    private let imageCacheService: ImageCacheServiceProtocol
    private var isAnimating = false
    
    // MARK: - UI Elements
    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumInteritemSpacing = 2
        layout.minimumLineSpacing = 2
        
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.backgroundColor = UIColor(resource: .white)
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(PhotoCell.self, forCellWithReuseIdentifier: PhotoCell.identifier)
        return collectionView
    }()
    
    private lazy var emptyStateLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Нет избранных фотографий"
        label.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.isHidden = true
        return label
    }()
    
    // MARK: - Initialization
    init(favoritesService: FavoritesServiceProtocol,
         imageCacheService: ImageCacheServiceProtocol) {
        self.favoritesService = favoritesService
        self.imageCacheService = imageCacheService
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupPresenter()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        presenter.loadFavorites()
    }
    
    // MARK: - Setup
    private func setupUI() {
        title = "Избранное"
        view.backgroundColor = UIColor(resource: .white)
        
        view.addSubview(collectionView)
        view.addSubview(emptyStateLabel)
        
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            emptyStateLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyStateLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    private func setupPresenter() {
        let networkService = NetworkService()
        presenter = FavoritesPresenter(networkService: networkService, favoritesService: favoritesService)
        presenter.view = self
    }
}

// MARK: - FavoritesViewProtocol
extension FavoritesViewController: FavoritesViewProtocol {
    func displayFavorites(_ photos: [Photo]) {
        self.photos = photos
        emptyStateLabel.isHidden = !photos.isEmpty
        collectionView.reloadData()
    }
    
    func showError(_ error: Error) {
        let alert = UIAlertController(title: "Ошибка", message: error.localizedDescription, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - UICollectionViewDataSource
extension FavoritesViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return photos.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PhotoCell.identifier, for: indexPath) as? PhotoCell else {
            return UICollectionViewCell()
        }
        
        let photo = photos[indexPath.item]
        cell.delegate = self
        cell.configure(with: photo, isFavorite: true, imageCacheService: imageCacheService)
        return cell
    }
}

// MARK: - UICollectionViewDelegate
extension FavoritesViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let detailVC = PhotoDetailViewController(
            photos: photos,
            currentIndex: indexPath.item,
            favoritesService: favoritesService,
            imageCacheService: imageCacheService
        )
        navigationController?.pushViewController(detailVC, animated: true)
    }
}

// MARK: - UICollectionViewDelegateFlowLayout
extension FavoritesViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = (collectionView.frame.width - 4) / 3
        return CGSize(width: width, height: width)
    }
}

// MARK: - PhotoCellDelegate
extension FavoritesViewController: PhotoCellDelegate {
    func photoCell(_ cell: PhotoCell, didTapFavoriteButton photo: Photo) {
        guard !isAnimating,
              let indexPath = collectionView.indexPath(for: cell),
              let index = photos.firstIndex(where: { $0.id == photo.id }) else { return }
        
        isAnimating = true
        collectionView.isUserInteractionEnabled = false
        
        cell.updateFavoriteStatus(isFavorite: false)
        
        photos.remove(at: index)
        
        UIView.animate(withDuration: 0.3, animations: {
            cell.alpha = 0
            cell.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        }) { [weak self] _ in
            guard let self = self else { return }
            
            self.collectionView.performBatchUpdates({
                self.collectionView.deleteItems(at: [indexPath])
            }, completion: { [weak self] _ in
                guard let self = self else { return }
                self.emptyStateLabel.isHidden = !self.photos.isEmpty
                self.presenter.removeFavorite(photo)
                
                self.isAnimating = false
                self.collectionView.isUserInteractionEnabled = true
            })
        }
    }
}

