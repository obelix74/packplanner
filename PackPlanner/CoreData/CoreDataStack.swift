//
//  CoreDataStack.swift
//  PackPlanner
//
//  Created for Core Data + CloudKit Migration
//

import Foundation
import CoreData
import CloudKit

class CoreDataStack {
    static let shared = CoreDataStack()

    private init() {}

    // MARK: - Core Data Stack

    lazy var persistentContainer: NSPersistentCloudKitContainer = {
        let container = NSPersistentCloudKitContainer(name: "PackPlanner")

        // Get the store description
        guard let description = container.persistentStoreDescriptions.first else {
            fatalError("Failed to retrieve persistent store description")
        }

        // Enable CloudKit sync
        description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        description.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)

        // CloudKit container configuration
        description.cloudKitContainerOptions = NSPersistentCloudKitContainerOptions(
            containerIdentifier: "iCloud.com.anand.PackPlanner"
        )

        container.loadPersistentStores { storeDescription, error in
            if let error = error as NSError? {
                // In production, handle this error appropriately
                // For now, we'll log it
                print("❌ Core Data failed to load: \(error), \(error.userInfo)")

                // Check for common CloudKit errors
                if let ckError = error.userInfo[NSUnderlyingErrorKey] as? CKError {
                    self.handleCloudKitError(ckError)
                }
            } else {
                print("✅ Core Data loaded successfully")
                print("📍 Store URL: \(storeDescription.url?.path ?? "unknown")")
            }
        }

        // Automatically merge changes from CloudKit
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy

        // Set up notifications for remote changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleRemoteChange),
            name: .NSPersistentStoreRemoteChange,
            object: container.persistentStoreCoordinator
        )

        return container
    }()

    var viewContext: NSManagedObjectContext {
        return persistentContainer.viewContext
    }

    // MARK: - Background Context

    func newBackgroundContext() -> NSManagedObjectContext {
        let context = persistentContainer.newBackgroundContext()
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return context
    }

    // MARK: - Save Context

    func saveContext() {
        let context = viewContext
        if context.hasChanges {
            do {
                try context.save()
                print("✅ Core Data context saved successfully")
            } catch {
                let nsError = error as NSError
                print("❌ Failed to save context: \(nsError), \(nsError.userInfo)")
                // In production, handle this appropriately
            }
        }
    }

    func saveContext(_ context: NSManagedObjectContext) {
        if context.hasChanges {
            do {
                try context.save()
                print("✅ Core Data context saved successfully")
            } catch {
                let nsError = error as NSError
                print("❌ Failed to save context: \(nsError), \(nsError.userInfo)")
            }
        }
    }

    // MARK: - CloudKit Status

    func checkCloudKitStatus(completion: @escaping (Bool, Error?) -> Void) {
        CKContainer(identifier: "iCloud.com.anand.PackPlanner").accountStatus { status, error in
            DispatchQueue.main.async {
                switch status {
                case .available:
                    print("✅ iCloud is available")
                    completion(true, nil)
                case .noAccount:
                    print("⚠️ No iCloud account")
                    completion(false, NSError(domain: "PackPlanner", code: 1, userInfo: [NSLocalizedDescriptionKey: "Please sign in to iCloud in Settings"]))
                case .restricted:
                    print("⚠️ iCloud is restricted")
                    completion(false, NSError(domain: "PackPlanner", code: 2, userInfo: [NSLocalizedDescriptionKey: "iCloud access is restricted"]))
                case .couldNotDetermine:
                    print("⚠️ Could not determine iCloud status")
                    completion(false, error)
                case .temporarilyUnavailable:
                    print("⚠️ iCloud temporarily unavailable")
                    completion(false, NSError(domain: "PackPlanner", code: 3, userInfo: [NSLocalizedDescriptionKey: "iCloud is temporarily unavailable"]))
                @unknown default:
                    print("⚠️ Unknown iCloud status")
                    completion(false, error)
                }
            }
        }
    }

    // MARK: - CloudKit Error Handling

    private func handleCloudKitError(_ error: CKError) {
        switch error.code {
        case .notAuthenticated:
            print("⚠️ User is not signed into iCloud")
        case .networkUnavailable, .networkFailure:
            print("⚠️ Network unavailable")
        case .quotaExceeded:
            print("⚠️ iCloud storage quota exceeded")
        case .managedAccountRestricted:
            print("⚠️ iCloud account is restricted")
        default:
            print("⚠️ CloudKit error: \(error.localizedDescription)")
        }
    }

    // MARK: - Remote Change Notification

    @objc private func handleRemoteChange(_ notification: Notification) {
        print("📡 Remote changes received from CloudKit")
        // Post a notification that the app can observe
        NotificationCenter.default.post(name: .cloudKitDataChanged, object: nil)
    }

    // MARK: - Batch Delete

    func deleteAllData() {
        let entities = ["GearEntity", "HikeEntity", "HikeGearEntity", "SettingsEntity"]

        for entity in entities {
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entity)
            let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)

            do {
                try viewContext.execute(batchDeleteRequest)
                print("✅ Deleted all \(entity) objects")
            } catch {
                print("❌ Failed to delete \(entity): \(error)")
            }
        }

        saveContext()
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let cloudKitDataChanged = Notification.Name("cloudKitDataChanged")
}
