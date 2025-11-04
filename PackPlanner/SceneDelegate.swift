//
//  SceneDelegate.swift
//  PackPlanner
//
//  Created by Kumar on 9/18/20.
//

import UIKit
import SwiftUI

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?


    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else { return }

        // Create the SwiftUI view hierarchy
        let window = UIWindow(windowScene: windowScene)

        // Create tab bar with SwiftUI views
        let tabBarController = createTabBarController()

        window.rootViewController = tabBarController
        self.window = window
        window.makeKeyAndVisible()
    }

    private func createTabBarController() -> UITabBarController {
        let tabBarController = UITabBarController()

        // Hike List Tab (SwiftUI)
        let hikeListView = HikeListView()
        let hikeListHost = UIHostingController(rootView: hikeListView)
        hikeListHost.tabBarItem = UITabBarItem(
            title: "Hikes",
            image: UIImage(systemName: "figure.hiking"),
            selectedImage: UIImage(systemName: "figure.hiking")
        )
        let hikeNavController = UINavigationController(rootViewController: hikeListHost)
        hikeNavController.navigationBar.prefersLargeTitles = false

        // Gear List Tab (SwiftUI)
        let gearListView = GearListView()
        let gearListHost = UIHostingController(rootView: gearListView)
        gearListHost.tabBarItem = UITabBarItem(
            title: "Gear",
            image: UIImage(systemName: "backpack"),
            selectedImage: UIImage(systemName: "backpack.fill")
        )
        let gearNavController = UINavigationController(rootViewController: gearListHost)
        gearNavController.navigationBar.prefersLargeTitles = false

        tabBarController.viewControllers = [hikeNavController, gearNavController]

        return tabBarController
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.
    }


}

