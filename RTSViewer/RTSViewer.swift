import CoreData
import SwiftUI
import RTSComponentKit

/**
 * Entry point to the Sample Application (SA) for the Millicast iOS SDK.
 */
@main
struct RTSViewer: App {

    private let persistentSettings = PersistentSettings()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark)
                .environmentObject(persistentSettings)
        }
    }
}
