import CoreData
import SwiftUI
import RTSComponentKit

/**
 * Entry point to the Sample Application (SA) for the Millicast iOS SDK.
 */
@main
struct RTSViewer: App {

    private let dataStore = RTSDataStore()
    private let persistenceManager = PersistenceManager()

    @Environment(\.scenePhase) var scenePhase

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark)
                .environmentObject(dataStore)
                .environmentObject(persistenceManager)
                .environment(\.managedObjectContext, persistenceManager.context)
        }
        .onChange(of: scenePhase) { newScenePhase in
            guard newScenePhase == .background else {
                return
            }
            persistenceManager.saveChanges()
        }
    }
}
