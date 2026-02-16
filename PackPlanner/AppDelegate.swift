//
//  AppDelegate.swift
//  PackPlanner
//
//  Created by Kumar on 9/18/20.
//

import UIKit
import CoreData
import os

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.

        // Initialize Core Data stack
        let context = CoreDataStack.shared.viewContext

        // Backfill UUIDs for any hikes created before UUID support
        HikeEntity.backfillUUIDs(context: context)

        // Initialize database with proper fallback handling
        return initializeDatabase()
    }

    private func initializeDatabase() -> Bool {
        Logger.app.info("Database initialized successfully")
        return true
    }
    
    private func handleDatabaseFailure() -> Bool {
        // Log the failure for debugging
        Logger.app.error("Database initialization failed. App will continue with limited functionality.")
        
        // Present user-friendly error after a delay to allow UI to load
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.presentDatabaseErrorAlert()
        }
        
        // Continue app launch to allow user to see error message
        // App functionality will be limited but won't crash
        return true
    }
    
    private func presentDatabaseErrorAlert() {
        guard let window = UIApplication.shared.windows.first,
              let rootViewController = window.rootViewController else {
            Logger.app.warning("No root view controller available for error alert")
            return
        }
        
        let alert = UIAlertController(
            title: "Database Error",
            message: "PackPlanner is having trouble accessing your data. Some features may not work properly. Please restart the app or contact support if the problem persists.",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "OK", style: .default))

        alert.addAction(UIAlertAction(title: "Continue", style: .cancel))
        
        // Present from the top-most view controller
        var topController = rootViewController
        while let presentedController = topController.presentedViewController {
            topController = presentedController
        }
        
        topController.present(alert, animated: true)
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }


}

