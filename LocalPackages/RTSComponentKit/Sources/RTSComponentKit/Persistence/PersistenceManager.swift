//
//  PersistenceManager.swift
//

import CoreData
import Foundation

public final class PersistenceManager: ObservableObject {

    enum Constants {
        static let maximumAllowedStreams = 25
    }

    static var managedObjectModel: NSManagedObjectModel = {
        guard let url = Bundle.module.url(forResource: "RTSViewer", withExtension: "momd") else {
            fatalError("Failed to locate momd file for TodoListsSwiftUI")
        }
        guard let model = NSManagedObjectModel(contentsOf: url) else {
            fatalError("Failed to load momd file for TodoListsSwiftUI")
        }
        return model
    }()

    public let container: NSPersistentContainer
    public var context: NSManagedObjectContext { container.viewContext }

    public init() {
        container = NSPersistentContainer(name: "RTSViewer", managedObjectModel: Self.managedObjectModel)

        container.loadPersistentStores { (_, error) in
            if let error = error {
                fatalError("Failed loading persistent stores with error: \(error.localizedDescription)")
            }
        }
    }

    public static var recentStreams: NSFetchRequest<StreamDetail> = {
        let request: NSFetchRequest<StreamDetail> = StreamDetail.fetchRequest()
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \StreamDetail.lastUsedDate, ascending: false)
        ]

        return request
    }()

    public func updateLastUsedDate(for streamDetail: StreamDetail) {
        streamDetail.lastUsedDate = Date()
        saveChanges()
    }

    public func saveStream(_ name: String, accountID: String) {
        let request: NSFetchRequest<StreamDetail> = StreamDetail.fetchRequest()
        request.predicate = NSPredicate(format: "name == %@ && accountID == %@", name, accountID)

        do {
            let fetchedResults = try context.fetch(request)
            let streamDetail: StreamDetail
            if let stream = fetchedResults.first {
                streamDetail = stream
                streamDetail.lastUsedDate = Date()
            } else {
                streamDetail = StreamDetail(context: context)
                streamDetail.accountID = accountID
                streamDetail.name = name
                streamDetail.lastUsedDate = Date()

                // Delete streams that are older and exceeding the maximum allowed count
                let request: NSFetchRequest<StreamDetail> = Self.recentStreams
                let updatedResults = try context.fetch(request)
                if updatedResults.count > Constants.maximumAllowedStreams {
                    let streamsToDelete = updatedResults[(Constants.maximumAllowedStreams)..<updatedResults.count]
                    streamsToDelete.forEach(context.delete)
                }
            }
            saveChanges()
        } catch {
            print("Failed to fetch existing data - \(error.localizedDescription)")
        }
    }

    public func saveChanges() {
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                print("Failed to save changes - \(error.localizedDescription)")
            }
        }
    }
}
