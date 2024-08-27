//
//  StreamDataManager.swift
//

import Combine
import CoreData
import Foundation

protocol StreamDataManagerProtocol: AnyObject {
    var streamDetailsSubject: CurrentValueSubject<[SavedStreamDetail], Never> { get }

    func fetchStreamDetails()
    func updateLastUsedDate(for streamDetail: SavedStreamDetail)
    func delete(streamDetail: SavedStreamDetail)
    func saveStream(_ streamDetail: SavedStreamDetail)
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

    private(set) var streamDetailsSubject: CurrentValueSubject<[SavedStreamDetail], Never> = .init([])

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

        self.streamDetailFetchResultsController = NSFetchedResultsController(fetchRequest: Self.recentStreamsFetchRequest,
                                                                             managedObjectContext: managedObjectContext,
                                                                             sectionNameKeyPath: nil,
                                                                             cacheName: nil)

        super.init()

        streamDetailFetchResultsController.delegate = self

        fetchStreamDetails()
    }

    func fetchStreamDetails() {
        try? streamDetailFetchResultsController.performFetch()
        if let newStreamDetails = streamDetailFetchResultsController.fetchedObjects, !newStreamDetails.isEmpty {
            let streamDetails = newStreamDetails.compactMap { SavedStreamDetail(managedObject: $0) }
            streamDetailsSubject.send(streamDetails)
        }
    }

    func delete(streamDetail: SavedStreamDetail) {
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

    func updateLastUsedDate(for streamDetail: SavedStreamDetail) {
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

    func saveStream(_ streamDetail: SavedStreamDetail) {
        let request: NSFetchRequest<StreamDetailManagedObject> = StreamDetailManagedObject.fetchRequest()
        request.predicate = NSPredicate(format: "streamName == %@ && accountID == %@", streamDetail.streamName, streamDetail.accountID)

        do {
            let fetchedResults = try coreDataManager.context.fetch(request)
            if let stream = fetchedResults.first {
                coreDataManager.context.delete(stream)
            }

            let streamDetailToSave = StreamDetailManagedObject(context: coreDataManager.context)
            streamDetailToSave.streamName = streamDetail.streamName
            streamDetailToSave.accountID = streamDetail.accountID
            streamDetailToSave.lastUsedDate = dateProvider.now
            streamDetailToSave.subscribeAPI = streamDetail.subscribeAPI
            streamDetailToSave.videoJitterMinimumDelayInMs = Int32(streamDetail.videoJitterMinimumDelayInMs)
            streamDetailToSave.minPlayoutDelay = streamDetail.minPlayoutDelay.map { NSNumber(value: $0) }
            streamDetailToSave.maxPlayoutDelay = streamDetail.maxPlayoutDelay.map { NSNumber(value: $0) }
            streamDetailToSave.disableAudio = streamDetail.disableAudio
            streamDetailToSave.primaryVideoQuality = streamDetail.primaryVideoQuality.rawValue
            streamDetailToSave.maxBitrate = streamDetail.maxBitrate.map { NSNumber(value: $0) }
            streamDetailToSave.forceSmooth = streamDetail.forceSmooth
            streamDetailToSave.saveLogs = streamDetail.saveLogs

            // Delete streams that are older and exceeding the maximum allowed count
            let request: NSFetchRequest<StreamDetailManagedObject> = Self.recentStreamsFetchRequest
            let updatedResults = try coreDataManager.context.fetch(request)
            if updatedResults.count > Constants.maximumAllowedStreams {
                let streamsToDelete = updatedResults[(Constants.maximumAllowedStreams) ..< updatedResults.count]
                streamsToDelete.forEach(coreDataManager.context.delete)
            }
            coreDataManager.saveContext()
        } catch {
            print("Failed to save stream - \(error.localizedDescription)")
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
            let streamDetails = newStreamDetails.compactMap { SavedStreamDetail(managedObject: $0) }
            streamDetailsSubject.send(streamDetails)
        }
    }
}
