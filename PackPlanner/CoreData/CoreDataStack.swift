//
//  CoreDataStack.swift
//  PackPlanner
//
//  Created for Core Data + CloudKit Migration
//

import Foundation
import CoreData
import CloudKit
import os

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
                Logger.coreData.error("Core Data failed to load: \(error), \(error.userInfo)")

                // Check for common CloudKit errors
                if let ckError = error.userInfo[NSUnderlyingErrorKey] as? CKError {
                    self.handleCloudKitError(ckError)
                }
            } else {
                Logger.coreData.info("Core Data loaded successfully")
                Logger.coreData.debug("Store URL: \(storeDescription.url?.path ?? "unknown")")
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
                Logger.coreData.debug("Context saved")
            } catch {
                let nsError = error as NSError
                Logger.coreData.error("Failed to save context: \(nsError), \(nsError.userInfo)")
                // In production, handle this appropriately
            }
        }
    }

    func saveContext(_ context: NSManagedObjectContext) {
        if context.hasChanges {
            do {
                try context.save()
                Logger.coreData.debug("Context saved")
            } catch {
                let nsError = error as NSError
                Logger.coreData.error("Failed to save context: \(nsError), \(nsError.userInfo)")
            }
        }
    }

    // MARK: - CloudKit Status

    func checkCloudKitStatus(completion: @escaping (Bool, Error?) -> Void) {
        CKContainer(identifier: "iCloud.com.anand.PackPlanner").accountStatus { status, error in
            DispatchQueue.main.async {
                switch status {
                case .available:
                    Logger.cloudKit.info("iCloud is available")
                    completion(true, nil)
                case .noAccount:
                    Logger.cloudKit.warning("No iCloud account")
                    completion(false, NSError(domain: "PackPlanner", code: 1, userInfo: [NSLocalizedDescriptionKey: "Please sign in to iCloud in Settings"]))
                case .restricted:
                    Logger.cloudKit.warning("iCloud is restricted")
                    completion(false, NSError(domain: "PackPlanner", code: 2, userInfo: [NSLocalizedDescriptionKey: "iCloud access is restricted"]))
                case .couldNotDetermine:
                    Logger.cloudKit.warning("Could not determine iCloud status")
                    completion(false, error)
                case .temporarilyUnavailable:
                    Logger.cloudKit.warning("iCloud temporarily unavailable")
                    completion(false, NSError(domain: "PackPlanner", code: 3, userInfo: [NSLocalizedDescriptionKey: "iCloud is temporarily unavailable"]))
                @unknown default:
                    Logger.cloudKit.warning("Unknown iCloud status")
                    completion(false, error)
                }
            }
        }
    }

    // MARK: - CloudKit Error Handling

    private func handleCloudKitError(_ error: CKError) {
        switch error.code {
        case .notAuthenticated:
            Logger.cloudKit.warning("User is not signed into iCloud")
        case .networkUnavailable, .networkFailure:
            Logger.cloudKit.warning("Network unavailable")
        case .quotaExceeded:
            Logger.cloudKit.warning("iCloud storage quota exceeded")
        case .managedAccountRestricted:
            Logger.cloudKit.warning("iCloud account is restricted")
        default:
            Logger.cloudKit.warning("CloudKit error: \(error.localizedDescription)")
        }
    }

    // MARK: - Remote Change Notification

    @objc private func handleRemoteChange(_ notification: Notification) {
        Logger.cloudKit.info("Remote changes received from CloudKit")
        // Post a notification that the app can observe
        NotificationCenter.default.post(name: .cloudKitDataChanged, object: nil)
    }

    // MARK: - Batch Delete

    func deleteAllData() {
        let entities = ["GearEntity", "HikeEntity", "HikeGearEntity", "SettingsEntity"]

        for entity in entities {
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entity)
            let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
            batchDeleteRequest.resultType = .resultTypeObjectIDs

            do {
                let result = try viewContext.execute(batchDeleteRequest) as? NSBatchDeleteResult
                if let objectIDs = result?.result as? [NSManagedObjectID] {
                    let changes = [NSDeletedObjectsKey: objectIDs]
                    NSManagedObjectContext.mergeChanges(fromRemoteContextSave: changes, into: [viewContext])
                }
            } catch {
                // Batch delete failed for this entity; continue with others
            }
        }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let cloudKitDataChanged = Notification.Name("cloudKitDataChanged")
}
