import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

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
            let galleryViewController = GalleryViewController()
            let navigationController = UINavigationController(rootViewController: galleryViewController)
            self.window?.rootViewController = navigationController
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

