//
//  AppDelegate.swift
//  PackPlanner
//
//  Created by Kumar on 9/18/20.
//

import UIKit
import RealmSwift

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        // Initialize database with proper fallback handling
        return initializeDatabase()
    }
    
    private func initializeDatabase() -> Bool {
        // Initialize SettingsManager - it has internal fallback handling
        _ = SettingsManager.SINGLETON.settings
        
        // Check if there was a critical database failure
        if DatabaseErrorHandler.shared.criticalDatabaseFailure {
            print("Critical database failure detected")
            return handleDatabaseFailure()
        }
        
        print("Database initialized successfully")
        return true
    }
    
    private func handleDatabaseFailure() -> Bool {
        // Log the failure for debugging
        print("Critical: Database initialization failed. App will continue with limited functionality.")
        
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
            print("No root view controller available for error alert")
            return
        }
        
        let alert = UIAlertController(
            title: "Database Error",
            message: "PackPlanner is having trouble accessing your data. Some features may not work properly. Please restart the app or contact support if the problem persists.",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Restart App", style: .default) { _ in
            exit(0) // Graceful restart - iOS will handle restart
        })
        
        alert.addAction(UIAlertAction(title: "Continue", style: .cancel) { _ in
            // Let user continue with limited functionality
            print("User chose to continue with database error")
        })
        
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

