//
//  PersistenceManager.swift
//

import CoreData
import Foundation

final class PersistenceManager: ObservableObject {

    enum Constants {
        static let maximumAllowedStreams = 25
    }

    static var managedObjectModel: NSManagedObjectModel = {
        guard let url = Bundle.main.url(forResource: "RTSViewer", withExtension: "momd") else {
            fatalError("Failed to locate momd file for TodoListsSwiftUI")
        }
        guard let model = NSManagedObjectModel(contentsOf: url) else {
            fatalError("Failed to load momd file for TodoListsSwiftUI")
        }
        return model
    }()

    let container: NSPersistentContainer
    var context: NSManagedObjectContext { container.viewContext }

    init() {
        container = NSPersistentContainer(name: "RTSViewer", managedObjectModel: Self.managedObjectModel)

        container.loadPersistentStores { (_, error) in
            if let error = error {
                fatalError("Failed loading persistent stores with error: \(error.localizedDescription)")
            }
        }
    }

    static var recentStreams: NSFetchRequest<StreamDetail> = {
        let request: NSFetchRequest<StreamDetail> = StreamDetail.fetchRequest()
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \StreamDetail.lastUsedDate, ascending: false)
        ]

        return request
    }()

    func updateLastUsedDate(for streamDetail: StreamDetail) {
        streamDetail.lastUsedDate = Date()
        saveChanges()
    }

    func saveStream(_ streamName: String, accountID: String) {
        let request: NSFetchRequest<StreamDetail> = StreamDetail.fetchRequest()
        request.predicate = NSPredicate(format: "streamName == %@ && accountID == %@", streamName, accountID)

        do {
            let fetchedResults = try context.fetch(request)
            let streamDetail: StreamDetail
            if let stream = fetchedResults.first {
                streamDetail = stream
                streamDetail.lastUsedDate = Date()
            } else {
                streamDetail = StreamDetail(context: context)
                streamDetail.accountID = accountID
                streamDetail.streamName = streamName
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

    func clearAllStreams() {
        let request: NSFetchRequest<StreamDetail> = Self.recentStreams
        do {
            let allStreams = try context.fetch(request)
            allStreams.forEach(context.delete)
            saveChanges()
        } catch {
            print("Failed to fetch existing data - \(error.localizedDescription)")
        }
    }

    func saveChanges() {
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                print("Failed to save changes - \(error.localizedDescription)")
            }
        }
    }
}
