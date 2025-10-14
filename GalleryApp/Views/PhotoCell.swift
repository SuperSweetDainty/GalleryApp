import UIKit

protocol PhotoCellDelegate: AnyObject {
    func photoCell(_ cell: PhotoCell, didTapFavoriteButton photo: Photo)
}

class PhotoCell: UICollectionViewCell {
    static let identifier = "PhotoCell"
    
    // MARK: - UI Elements
    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.backgroundColor = .systemGray5
        return imageView
    }()
    
    private let favoriteButton: UIButton = {
        let button = UIButton(type: .custom)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(UIImage(systemName: "heart"), for: .normal)
        button.setImage(UIImage(systemName: "heart.fill"), for: .selected)
        button.tintColor = .systemRed
        button.isUserInteractionEnabled = true
        return button
    }()
    
    private let loadingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.hidesWhenStopped = true
        return indicator
    }()
    
    // MARK: - Properties
    var photo: Photo?
    weak var delegate: PhotoCellDelegate?
    
    // MARK: - Initialization
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    private func setupUI() {
        contentView.addSubview(imageView)
        contentView.addSubview(favoriteButton)
        contentView.addSubview(loadingIndicator)
        
        favoriteButton.addTarget(self, action: #selector(favoriteButtonTapped), for: .touchUpInside)
        
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            
            favoriteButton.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 0),
            favoriteButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: 0),
            favoriteButton.widthAnchor.constraint(equalToConstant: 44),
            favoriteButton.heightAnchor.constraint(equalToConstant: 44),
            
            loadingIndicator.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
    }
    
    // MARK: - Configuration
    func configure(with photo: Photo, isFavorite: Bool) {
        self.photo = photo
        favoriteButton.isSelected = isFavorite
        
        loadImage()
    }
    
    private func loadImage() {
        guard let photo = photo else { return }
        
        loadingIndicator.startAnimating()
        
        ImageCacheService.shared.loadImage(from: photo.urls.small) { [weak self] image in
            DispatchQueue.main.async {
                self?.loadingIndicator.stopAnimating()
                self?.imageView.image = image
            }
        }
    }
    
    func updateFavoriteStatus(isFavorite: Bool) {
        favoriteButton.isSelected = isFavorite
    }
    
    // MARK: - Actions
    @objc private func favoriteButtonTapped() {
        guard let photo = photo else { return }
        delegate?.photoCell(self, didTapFavoriteButton: photo)
    }
    
    // MARK: - Reuse
    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.image = nil
        favoriteButton.isSelected = false
        loadingIndicator.stopAnimating()
        photo = nil
    }
}
