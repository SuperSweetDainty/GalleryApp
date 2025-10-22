import UIKit

final class PhotoDetailViewController: UIViewController {
    
    // MARK: - Enums
    private enum AnimationDirection {
        case left, right
    }
    
    // MARK: - Properties
    private var presenter: PhotoDetailPresenterProtocol!
    private let imageCacheService: ImageCacheServiceProtocol
    
    // MARK: - UI Elements
    private lazy var mainScrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsVerticalScrollIndicator = true
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.alwaysBounceVertical = true
        return scrollView
    }()
    
    private lazy var contentView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private lazy var imageScrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.delegate = self
        scrollView.minimumZoomScale = 1.0
        scrollView.maximumZoomScale = 3.0
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.layer.cornerRadius = 12
        scrollView.clipsToBounds = true
        return scrollView
    }()
    
    private lazy var imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFill
        imageView.backgroundColor = .systemGray6
        return imageView
    }()
    
    private lazy var favoriteButton: UIButton = {
        let button = UIButton(type: .custom)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(UIImage(systemName: "heart"), for: .normal)
        button.setImage(UIImage(systemName: "heart.fill"), for: .selected)
        button.tintColor = .systemRed
        button.addTarget(self, action: #selector(favoriteButtonTapped), for: .touchUpInside)
        return button
    }()
    
    private lazy var infoView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = UIColor(resource: .white)
        view.layer.cornerRadius = 16
        view.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        return view
    }()
    
    private lazy var authorLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.boldSystemFont(ofSize: 18)
        label.textColor = .label
        return label
    }()
    
    private lazy var descriptionLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 16)
        label.textColor = .secondaryLabel
        label.numberOfLines = 0
        return label
    }()
    
    private lazy var loadingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.hidesWhenStopped = true
        return indicator
    }()
    
    private lazy var animatedHeartImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        imageView.alpha = 0
        imageView.tintColor = .systemRed
        return imageView
    }()
    
    // MARK: - Initialization
    init(photos: [Photo],
         currentIndex: Int,
         favoritesService: FavoritesServiceProtocol,
         imageCacheService: ImageCacheServiceProtocol) {
        self.imageCacheService = imageCacheService
        super.init(nibName: nil, bundle: nil)
        
        self.presenter = PhotoDetailPresenter(
            photos: photos,
            currentIndex: currentIndex,
            favoritesService: favoritesService
        )
        self.presenter.view = self
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationBar()
        setupUI()
        presenter.loadPhoto()
        setupNotifications()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tabBarController?.tabBar.isHidden = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        tabBarController?.tabBar.isHidden = false
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        coordinator.animate(alongsideTransition: { _ in
            self.updateImageHeight()
        })
    }
    
    // MARK: - Setup
    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(favoritesDidChange),
            name: .favoritesDidChange,
            object: nil
        )
    }
    
    @objc private func favoritesDidChange(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let photoId = userInfo["photoId"] as? String,
              let isFavorite = userInfo["isFavorite"] as? Bool else {
            return
        }
        
        let currentPhoto = presenter.getCurrentPhoto()
        if currentPhoto.id == photoId {
            favoriteButton.isSelected = isFavorite
        }
    }
    
    private func updateImageHeight() {
        for constraint in imageScrollView.constraints {
            if constraint.firstAttribute == .height {
                constraint.constant = calculateOptimalImageHeight()
                break
            }
        }
        
        view.layoutIfNeeded()
    }
    
    private func setupNavigationBar() {
        title = ""
        navigationController?.navigationBar.tintColor = UIColor(resource: .black)
        
        favoriteButton.setImage(UIImage(systemName: "heart"), for: .normal)
        favoriteButton.setImage(UIImage(systemName: "heart.fill"), for: .selected)
        favoriteButton.tintColor = .systemRed
        
        let favoriteBarButton = UIBarButtonItem(customView: favoriteButton)
        navigationItem.rightBarButtonItem = favoriteBarButton
        
        favoriteButton.widthAnchor.constraint(equalToConstant: 44).isActive = true
        favoriteButton.heightAnchor.constraint(equalToConstant: 44).isActive = true
    }
    
    private func setupUI() {
        view.backgroundColor = UIColor(resource: .white)
        
        view.addSubview(mainScrollView)
        mainScrollView.addSubview(contentView)
        contentView.addSubview(imageScrollView)
        imageScrollView.addSubview(imageView)
        imageScrollView.addSubview(loadingIndicator)
        imageScrollView.addSubview(animatedHeartImageView)
        
        let doubleTapGesture = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap))
        doubleTapGesture.numberOfTapsRequired = 2
        imageView.addGestureRecognizer(doubleTapGesture)
        imageView.isUserInteractionEnabled = true
        
        let leftSwipeGesture = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe))
        leftSwipeGesture.direction = .left
        view.addGestureRecognizer(leftSwipeGesture)
        
        let rightSwipeGesture = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe))
        rightSwipeGesture.direction = .right
        view.addGestureRecognizer(rightSwipeGesture)
        
        contentView.addSubview(infoView)
        infoView.addSubview(authorLabel)
        infoView.addSubview(descriptionLabel)
        
        NSLayoutConstraint.activate([
            mainScrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            mainScrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            mainScrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            mainScrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            contentView.topAnchor.constraint(equalTo: mainScrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: mainScrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: mainScrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: mainScrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: mainScrollView.widthAnchor),
            
            imageScrollView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            imageScrollView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            imageScrollView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            imageScrollView.heightAnchor.constraint(equalToConstant: calculateOptimalImageHeight()),
            
            imageView.topAnchor.constraint(equalTo: imageScrollView.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: imageScrollView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: imageScrollView.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: imageScrollView.bottomAnchor),
            imageView.widthAnchor.constraint(equalTo: imageScrollView.widthAnchor),
            imageView.heightAnchor.constraint(equalTo: imageScrollView.heightAnchor),
            
            infoView.topAnchor.constraint(equalTo: imageScrollView.bottomAnchor, constant: 16),
            infoView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            infoView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            infoView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16),
            
            authorLabel.topAnchor.constraint(equalTo: infoView.topAnchor, constant: 16),
            authorLabel.leadingAnchor.constraint(equalTo: infoView.leadingAnchor, constant: 16),
            authorLabel.trailingAnchor.constraint(equalTo: infoView.trailingAnchor, constant: -16),
            
            descriptionLabel.topAnchor.constraint(equalTo: authorLabel.bottomAnchor, constant: 8),
            descriptionLabel.leadingAnchor.constraint(equalTo: infoView.leadingAnchor, constant: 16),
            descriptionLabel.trailingAnchor.constraint(equalTo: infoView.trailingAnchor, constant: -16),
            descriptionLabel.bottomAnchor.constraint(equalTo: infoView.bottomAnchor, constant: -16),
            
            loadingIndicator.centerXAnchor.constraint(equalTo: imageScrollView.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: imageScrollView.centerYAnchor),
            
            animatedHeartImageView.centerXAnchor.constraint(equalTo: imageScrollView.centerXAnchor),
            animatedHeartImageView.centerYAnchor.constraint(equalTo: imageScrollView.centerYAnchor),
            animatedHeartImageView.widthAnchor.constraint(equalToConstant: 80),
            animatedHeartImageView.heightAnchor.constraint(equalToConstant: 80)
        ])
    }
    
    // MARK: - Actions
    @objc private func favoriteButtonTapped() {
        presenter.toggleFavorite()
    }
    
    @objc private func handleDoubleTap() {
        presenter.toggleFavorite()
        showAnimatedHeart()
    }
    
    @objc private func handleSwipe(_ gesture: UISwipeGestureRecognizer) {
        switch gesture.direction {
        case .left:
            navigateToNextPhoto()
        case .right:
            navigateToPreviousPhoto()
        default:
            break
        }
    }
    
    private func navigateToNextPhoto() {
        guard presenter.canNavigateToNext() else {
            showSwipeMessage("Это последнее изображение")
            return
        }
        
        animateNavigation(direction: .left) {
            self.presenter.navigateToNext()
        }
    }
    
    private func navigateToPreviousPhoto() {
        guard presenter.canNavigateToPrevious() else {
            showSwipeMessage("Это первое изображение")
            return
        }
        
        animateNavigation(direction: .right) {
            self.presenter.navigateToPrevious()
        }
    }
    
    private func animateNavigation(direction: AnimationDirection, completion: @escaping () -> Void) {
        let nextTransform: CGAffineTransform
        
        switch direction {
        case .left:
            nextTransform = CGAffineTransform(translationX: view.frame.width, y: 0)
        case .right:
            nextTransform = CGAffineTransform(translationX: -view.frame.width, y: 0)
        }
        
        imageView.transform = nextTransform
        authorLabel.transform = nextTransform
        descriptionLabel.transform = nextTransform
        
        completion()
        
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseInOut, animations: {
            self.imageView.transform = .identity
            self.authorLabel.transform = .identity
            self.descriptionLabel.transform = .identity
        })
    }
    
    private func showSwipeMessage(_ message: String) {
        let messageLabel = UILabel()
        messageLabel.text = message
        messageLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        messageLabel.textColor = .white
        messageLabel.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        messageLabel.textAlignment = .center
        messageLabel.layer.cornerRadius = 8
        messageLabel.clipsToBounds = true
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        messageLabel.numberOfLines = 0
        messageLabel.lineBreakMode = .byWordWrapping
        
        view.addSubview(messageLabel)
        
        let maxWidth: CGFloat = 250
        let textSize = message.size(withAttributes: [.font: messageLabel.font!])
        let labelWidth = min(textSize.width + 20, maxWidth)
        
        NSLayoutConstraint.activate([
            messageLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            messageLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            messageLabel.widthAnchor.constraint(equalToConstant: labelWidth),
            messageLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: 40)
        ])
        
        messageLabel.alpha = 0
        UIView.animate(withDuration: 0.3, animations: {
            messageLabel.alpha = 1
        }) { _ in
            UIView.animate(withDuration: 0.3, delay: 1.0, animations: {
                messageLabel.alpha = 0
            }) { _ in
                messageLabel.removeFromSuperview()
            }
        }
    }
    
    private func showAnimatedHeart() {
        let currentPhoto = presenter.getCurrentPhoto()
        let isFavorite = presenter.isFavorite(currentPhoto)
        animatedHeartImageView.image = UIImage(systemName: isFavorite ? "heart.fill" : "heart")
        
        animatedHeartImageView.layer.removeAllAnimations()
        animatedHeartImageView.alpha = 0
        animatedHeartImageView.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
        
        UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.6, initialSpringVelocity: 0.8, options: .curveEaseOut) {
            self.animatedHeartImageView.alpha = 1.0
            self.animatedHeartImageView.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
        } completion: { _ in
            UIView.animate(withDuration: 0.3, delay: 0.7, options: .curveEaseIn) {
                self.animatedHeartImageView.alpha = 0
                self.animatedHeartImageView.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
            }
        }
    }
    
    private func calculateOptimalImageHeight() -> CGFloat {
        let screenHeight = UIScreen.main.bounds.height
        let screenWidth = UIScreen.main.bounds.width
        let availableWidth = screenWidth - 32
        
        let baseHeightPercentage: CGFloat
        switch screenHeight {
        case 0...667:
            baseHeightPercentage = 0.75
        case 668...812:
            baseHeightPercentage = 0.7
        case 813...926:
            baseHeightPercentage = 0.7
        case 927...1024:
            baseHeightPercentage = 0.7
        default:
            baseHeightPercentage = 0.55
        }
        
        let baseHeight = screenHeight * baseHeightPercentage
        
        let photo = presenter.getCurrentPhoto()
        let aspectRatio = CGFloat(photo.width) / CGFloat(photo.height)
        let heightBasedOnWidth = availableWidth / aspectRatio
        
        let optimalHeight = min(baseHeight, heightBasedOnWidth)
        return max(200, min(optimalHeight, screenHeight * 0.85))
    }
}

// MARK: - PhotoDetailViewProtocol
extension PhotoDetailViewController: PhotoDetailViewProtocol {
    func displayPhoto(_ photo: Photo) {
        authorLabel.text = photo.user.name
        descriptionLabel.text = photo.description ?? photo.altDescription ?? "Описание отсутствует"
        
        loadingIndicator.startAnimating()
        imageView.image = nil
        
        imageCacheService.loadImage(from: photo.urls.regular) { [weak self] image in
            DispatchQueue.main.async {
                self?.loadingIndicator.stopAnimating()
                self?.imageView.image = image
            }
        }
    }
    
    func showError(_ error: Error) {
        let alert = UIAlertController(title: "Ошибка", message: error.localizedDescription, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    func updateFavoriteButton(isFavorite: Bool) {
        favoriteButton.isSelected = isFavorite
    }
}

// MARK: - UIScrollViewDelegate
extension PhotoDetailViewController: UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return scrollView == imageScrollView ? imageView : nil
    }
    
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        guard scrollView == imageScrollView else { return }
        
        let offsetX = max((scrollView.bounds.width - scrollView.contentSize.width) * 0.5, 0)
        let offsetY = max((scrollView.bounds.height - scrollView.contentSize.height) * 0.5, 0)
        
        imageView.center = CGPoint(
            x: scrollView.contentSize.width * 0.5 + offsetX,
            y: scrollView.contentSize.height * 0.5 + offsetY
        )
    }
}
