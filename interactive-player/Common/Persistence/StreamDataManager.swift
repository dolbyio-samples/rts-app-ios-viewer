//
//  StreamDataManager.swift
//

import Combine
import CoreData
import Foundation

protocol StreamDataManagerProtocol: AnyObject {
    var streamDetailsSubject: CurrentValueSubject<[StreamDetail], Never> { get }

    func fetchStreamDetails()
    func updateLastUsedDate(for streamDetail: StreamDetail)
    func delete(streamDetail: StreamDetail)
    func saveStream(_ streamName: String, accountID: String, dev: Bool, forcePlayoutDelay: Bool, disableAudio: Bool, saveLogs: Bool)
    func clearAllStreams()
}

final class StreamDataManager: NSObject, StreamDataManagerProtocol {

    enum StreamDataManagerType {
        case `default`, testing
    }

    enum Constants {
        static let maximumAllowedStreams = 25
    }

    static let shared = StreamDataManager(type: .default)

    private(set) var streamDetailsSubject: CurrentValueSubject<[StreamDetail], Never> = .init([])

    private let dateProvider: DateProvider
    private let coreDataManager: CoreDataManager
    private let managedObjectContext: NSManagedObjectContext
    private let streamDetailFetchResultsController: NSFetchedResultsController<StreamDetailManagedObject>

    private static var recentStreamsFetchRequest: NSFetchRequest<StreamDetailManagedObject> = {
        let request: NSFetchRequest<StreamDetailManagedObject> = StreamDetailManagedObject.fetchRequest()
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \StreamDetailManagedObject.lastUsedDate, ascending: false)
        ]

        return request
    }()

    init(type: StreamDataManagerType, dateProvider: DateProvider = DefaultDateProvider()) {
        switch type {
        case .default:
            self.coreDataManager = CoreDataManager()
            self.managedObjectContext = coreDataManager.context
        case .testing:
            self.coreDataManager = CoreDataManager(inMemory: true)
            self.managedObjectContext = coreDataManager.context
        }
        self.dateProvider = dateProvider

        streamDetailFetchResultsController = NSFetchedResultsController(fetchRequest: Self.recentStreamsFetchRequest,
                                                                        managedObjectContext: managedObjectContext,
                                                                        sectionNameKeyPath: nil,
                                                                        cacheName: nil)

        super.init()

        streamDetailFetchResultsController.delegate = self

        fetchStreamDetails()
    }

    func fetchStreamDetails() {
        try? streamDetailFetchResultsController.performFetch()
        if let newStreamDetails = streamDetailFetchResultsController.fetchedObjects {
            let streamDetails = newStreamDetails.compactMap { StreamDetail(managedObject: $0) }
            streamDetailsSubject.send(streamDetails)
        }
    }

    func delete(streamDetail: StreamDetail) {
        let request: NSFetchRequest<StreamDetailManagedObject> = StreamDetailManagedObject.fetchRequest()
        request.predicate = NSPredicate(
            format: "streamName == %@ && accountID == %@",
            streamDetail.streamName,
            streamDetail.accountID
        )

        do {
            let fetchedResults = try coreDataManager.context.fetch(request)
            guard let stream = fetchedResults.first else {
                print("Failed to fetch stream detail - \(streamDetail)")
                return
            }
            coreDataManager.context.delete(stream)
            coreDataManager.saveContext()
        } catch {
            print("Failed to fetch stream detail - \(streamDetail)")
        }
    }

    func updateLastUsedDate(for streamDetail: StreamDetail) {
        let request: NSFetchRequest<StreamDetailManagedObject> = StreamDetailManagedObject.fetchRequest()
        request.predicate = NSPredicate(
            format: "streamName == %@ && accountID == %@",
            streamDetail.streamName,
            streamDetail.accountID
        )

        do {
            let fetchedResults = try coreDataManager.context.fetch(request)
            let streamDetailManagedObject: StreamDetailManagedObject
            guard let stream = fetchedResults.first else {
                print("Failed to fetch stream detail - \(streamDetail)")
                return
            }
            streamDetailManagedObject = stream
            streamDetailManagedObject.lastUsedDate = dateProvider.now
            coreDataManager.saveContext()
        } catch {
            print("Failed to fetch stream detail - \(streamDetail)")
        }
    }

    func saveStream(_ streamName: String, accountID: String, dev: Bool, forcePlayoutDelay: Bool, disableAudio: Bool, saveLogs: Bool) {
        let request: NSFetchRequest<StreamDetailManagedObject> = StreamDetailManagedObject.fetchRequest()
        request.predicate = NSPredicate(format: "streamName == %@ && accountID == %@", streamName, accountID)

        do {
            let fetchedResults = try coreDataManager.context.fetch(request)
            let streamDetail: StreamDetailManagedObject
            if let stream = fetchedResults.first {
                streamDetail = stream
                streamDetail.lastUsedDate = dateProvider.now
            } else {
                streamDetail = StreamDetailManagedObject(context: coreDataManager.context)
                streamDetail.accountID = accountID
                streamDetail.streamName = streamName
                streamDetail.lastUsedDate = dateProvider.now
                streamDetail.disableAudio = disableAudio ? "true" : "false"
                streamDetail.isDev = dev ? "true" : "false"
                streamDetail.forcePlayoutDelay = forcePlayoutDelay ? "true" : "false"
                streamDetail.saveLogs = saveLogs ? "true" : "false"

                // Delete streams that are older and exceeding the maximum allowed count
                let request: NSFetchRequest<StreamDetailManagedObject> = Self.recentStreamsFetchRequest
                let updatedResults = try coreDataManager.context.fetch(request)
                if updatedResults.count > Constants.maximumAllowedStreams {
                    let streamsToDelete = updatedResults[(Constants.maximumAllowedStreams)..<updatedResults.count]
                    streamsToDelete.forEach(coreDataManager.context.delete)
                }
            }
            coreDataManager.saveContext()
        } catch {
            print("Failed to fetch existing data - \(error.localizedDescription)")
        }
    }

    func clearAllStreams() {
        let request: NSFetchRequest<StreamDetailManagedObject> = Self.recentStreamsFetchRequest
        do {
            let allStreams = try coreDataManager.context.fetch(request)
            allStreams.forEach(coreDataManager.context.delete)
            coreDataManager.saveContext()
        } catch {
            print("Failed to fetch existing data - \(error.localizedDescription)")
        }
    }
}

extension StreamDataManager: NSFetchedResultsControllerDelegate {

    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        if let newStreamDetails = controller.fetchedObjects as? [StreamDetailManagedObject] {
            let streamDetails = newStreamDetails.compactMap { StreamDetail(managedObject: $0) }
            streamDetailsSubject.send(streamDetails)
        }
    }
}
