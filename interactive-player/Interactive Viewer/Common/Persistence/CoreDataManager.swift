//
//  CoreDataManager.swift
//

import CoreData
import Foundation

final class CoreDataManager {

    let container: NSPersistentContainer
    var context: NSManagedObjectContext { container.viewContext }

    private static var managedObjectModel: NSManagedObjectModel = {
        guard let url = Bundle(for: CoreDataManager.self).url(forResource: "RTSViewer", withExtension: "momd") else {
            fatalError("Failed to locate momd file")
        }
        guard let model = NSManagedObjectModel(contentsOf: url) else {
            fatalError("Failed to load momd file")
        }
        return model
    }()

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "RTSViewer", managedObjectModel: Self.managedObjectModel)
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        container.loadPersistentStores(completionHandler: { _, error in
            if let error = error {
//                fatalError("Failed loading persistent stores with error: \(error.localizedDescription)")
                print("$$$ \("Failed loading persistent stores with error: \(error.localizedDescription)")")
            }
        })
    }

    func saveContext() {
        if context.hasChanges {
            do {
                try context.save()
            } catch let error as NSError {
                print("Failed to save changes - \(error.localizedDescription)")
            }
        }
    }
}
