import UIKit

class PhotoDetailViewController: UIViewController {
    
    // MARK: - Properties
    private var presenter: PhotoDetailPresenterProtocol!
    private let photo: Photo
    
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
        button.setImage(UIImage(named: "Dislike"), for: .normal)
        button.setImage(UIImage(named: "Like"), for: .selected)
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
    init(photo: Photo) {
        self.photo = photo
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationBar()
        setupUI()
        setupPresenter()
        presenter.loadPhoto()
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        coordinator.animate(alongsideTransition: { _ in
            // Обновляем высоту изображения при повороте экрана
            self.updateImageHeight()
        })
    }
    
    private func updateImageHeight() {
        // Находим констрейнт высоты imageScrollView и обновляем его
        for constraint in imageScrollView.constraints {
            if constraint.firstAttribute == .height {
                constraint.constant = calculateOptimalImageHeight()
                break
            }
        }
        
        // Обновляем layout
        view.layoutIfNeeded()
    }
    
    // MARK: - Setup
    private func setupNavigationBar() {
        // Убираем текст из title
        title = ""
        
        // Настраиваем черный цвет для кнопки "Назад"
        navigationController?.navigationBar.tintColor = UIColor(resource: .black)
        
        // Настраиваем кнопку лайка с системными иконками
        favoriteButton.setImage(UIImage(systemName: "heart"), for: .normal)
        favoriteButton.setImage(UIImage(systemName: "heart.fill"), for: .selected)
        favoriteButton.tintColor = .systemRed
        
        // Добавляем кнопку лайка в навигационный бар справа
        let favoriteBarButton = UIBarButtonItem(customView: favoriteButton)
        navigationItem.rightBarButtonItem = favoriteBarButton
        
        // Устанавливаем размеры кнопки
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
        
        // Добавляем двойное нажатие для лайка
        let doubleTapGesture = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap))
        doubleTapGesture.numberOfTapsRequired = 2
        imageView.addGestureRecognizer(doubleTapGesture)
        imageView.isUserInteractionEnabled = true
        
        contentView.addSubview(infoView)
        infoView.addSubview(authorLabel)
        infoView.addSubview(descriptionLabel)
        
        NSLayoutConstraint.activate([
            // Main scroll view
            mainScrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            mainScrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            mainScrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            mainScrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // Content view
            contentView.topAnchor.constraint(equalTo: mainScrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: mainScrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: mainScrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: mainScrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: mainScrollView.widthAnchor),
            
            // Image scroll view
            imageScrollView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            imageScrollView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            imageScrollView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            imageScrollView.heightAnchor.constraint(equalToConstant: calculateOptimalImageHeight()),
            
            // Image view
            imageView.topAnchor.constraint(equalTo: imageScrollView.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: imageScrollView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: imageScrollView.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: imageScrollView.bottomAnchor),
            imageView.widthAnchor.constraint(equalTo: imageScrollView.widthAnchor),
            imageView.heightAnchor.constraint(equalTo: imageScrollView.heightAnchor),
            
            // Info view
            infoView.topAnchor.constraint(equalTo: imageScrollView.bottomAnchor, constant: 16),
            infoView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            infoView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            infoView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16),
            
            // Author label
            authorLabel.topAnchor.constraint(equalTo: infoView.topAnchor, constant: 16),
            authorLabel.leadingAnchor.constraint(equalTo: infoView.leadingAnchor, constant: 16),
            authorLabel.trailingAnchor.constraint(equalTo: infoView.trailingAnchor, constant: -16),
            
            // Description label
            descriptionLabel.topAnchor.constraint(equalTo: authorLabel.bottomAnchor, constant: 8),
            descriptionLabel.leadingAnchor.constraint(equalTo: infoView.leadingAnchor, constant: 16),
            descriptionLabel.trailingAnchor.constraint(equalTo: infoView.trailingAnchor, constant: -16),
            descriptionLabel.bottomAnchor.constraint(equalTo: infoView.bottomAnchor, constant: -16),
            
            
            // Loading indicator
            loadingIndicator.centerXAnchor.constraint(equalTo: imageScrollView.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: imageScrollView.centerYAnchor),
            
            // Animated heart
            animatedHeartImageView.centerXAnchor.constraint(equalTo: imageScrollView.centerXAnchor),
            animatedHeartImageView.centerYAnchor.constraint(equalTo: imageScrollView.centerYAnchor),
            animatedHeartImageView.widthAnchor.constraint(equalToConstant: 80),
            animatedHeartImageView.heightAnchor.constraint(equalToConstant: 80)
        ])
    }
    
    private func setupPresenter() {
        presenter = PhotoDetailPresenter(photo: photo)
        presenter.view = self
    }
    
    // MARK: - Actions
    @objc private func favoriteButtonTapped() {
        presenter.toggleFavorite()
    }
    
    @objc private func handleDoubleTap() {
        presenter.toggleFavorite()
        showAnimatedHeart()
    }
    
    private func showAnimatedHeart() {
        // Устанавливаем правильную иконку сердца в зависимости от состояния
        let isFavorite = presenter.isFavorite(photo)
        animatedHeartImageView.image = UIImage(systemName: isFavorite ? "heart.fill" : "heart")
        
        // Сбрасываем анимацию
        animatedHeartImageView.layer.removeAllAnimations()
        animatedHeartImageView.alpha = 0
        animatedHeartImageView.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
        
        // Анимация появления
        UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.6, initialSpringVelocity: 0.8, options: .curveEaseOut) {
            self.animatedHeartImageView.alpha = 1.0
            self.animatedHeartImageView.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
        } completion: { _ in
            // Анимация исчезновения через секунду
            UIView.animate(withDuration: 0.3, delay: 0.7, options: .curveEaseIn) {
                self.animatedHeartImageView.alpha = 0
                self.animatedHeartImageView.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
            }
        }
    }
    
    private func calculateOptimalImageHeight() -> CGFloat {
        let screenHeight = UIScreen.main.bounds.height
        let screenWidth = UIScreen.main.bounds.width
        let availableWidth = screenWidth - 32 // Учитываем отступы (16 с каждой стороны)
        
        // Базовый процент от высоты экрана в зависимости от размера устройства
        let baseHeightPercentage: CGFloat
        switch screenHeight {
        case 0...667: // iPhone SE, 8, 7, 6s, 6
            baseHeightPercentage = 0.75 // Увеличено с 60% до 75%
        case 668...812: // iPhone X, XS, 11 Pro, 12 mini, 13 mini
            baseHeightPercentage = 0.7 // Увеличено с 55% до 70%
        case 813...926: // iPhone XR, XS Max, 11, 11 Pro Max, 12, 12 Pro, 13, 13 Pro, 14
            baseHeightPercentage = 0.7 // Увеличено с 50% до 65%
        case 927...1024: // iPhone 14 Plus, 15, 15 Plus
            baseHeightPercentage = 0.7 // Увеличено с 45% до 60%
        default: // iPhone Pro Max модели и планшеты
            baseHeightPercentage = 0.55 // Увеличено с 40% до 55%
        }
        
        // Рассчитываем базовую высоту
        let baseHeight = screenHeight * baseHeightPercentage
        
        // Если у нас есть информация о соотношении сторон изображения, используем её
        let photo = self.photo
        let aspectRatio = CGFloat(photo.width) / CGFloat(photo.height)
        let heightBasedOnWidth = availableWidth / aspectRatio
        
        // Используем меньшую из высот (базовую или рассчитанную по соотношению сторон)
        // но не меньше 200 и не больше 85% экрана (увеличено с 80%)
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
        
        ImageCacheService.shared.loadImage(from: photo.urls.regular) { [weak self] image in
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
    
    func showLoading(_ isLoading: Bool) {
        if isLoading {
            loadingIndicator.startAnimating()
        } else {
            loadingIndicator.stopAnimating()
        }
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
