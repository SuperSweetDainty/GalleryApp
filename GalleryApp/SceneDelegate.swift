import UIKit

final class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    
    var window: UIWindow?


    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        
        window = UIWindow(windowScene: windowScene)
        
        let launchViewController = UIViewController()
        launchViewController.view.backgroundColor = .systemBackground
        
        let titleLabel = UILabel()
        titleLabel.text = "Gallery App"
        titleLabel.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        titleLabel.textColor = .label
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        launchViewController.view.addSubview(titleLabel)
        
        NSLayoutConstraint.activate([
            titleLabel.centerXAnchor.constraint(equalTo: launchViewController.view.centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: launchViewController.view.centerYAnchor)
        ])
        
        window?.rootViewController = launchViewController
        window?.makeKeyAndVisible()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            let favoritesService = FavoritesService()
            let imageCacheService = ImageCacheService()
            
            let galleryViewController = GalleryViewController(
                favoritesService: favoritesService,
                imageCacheService: imageCacheService
            )
            galleryViewController.tabBarItem = UITabBarItem(
                title: "Галерея",
                image: UIImage(systemName: "photo.on.rectangle"),
                selectedImage: UIImage(systemName: "photo.on.rectangle.fill")
            )
            let galleryNav = UINavigationController(rootViewController: galleryViewController)
            
            let favoritesViewController = FavoritesViewController(
                favoritesService: favoritesService,
                imageCacheService: imageCacheService
            )
            favoritesViewController.tabBarItem = UITabBarItem(
                title: "Избранное",
                image: UIImage(systemName: "heart"),
                selectedImage: UIImage(systemName: "heart.fill")
            )
            let favoritesNav = UINavigationController(rootViewController: favoritesViewController)
            
            let tabBarController = UITabBarController()
            tabBarController.viewControllers = [galleryNav, favoritesNav]
            tabBarController.tabBar.tintColor = .systemRed
            
            self.window?.rootViewController = tabBarController
        }
    }

    func sceneDidDisconnect(_ scene: UIScene) {
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
    }

    func sceneWillResignActive(_ scene: UIScene) {
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
    }


}

