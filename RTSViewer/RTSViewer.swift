import CoreData
import SwiftUI
import RTSComponentKit

/**
 * Entry point to the Sample Application (SA) for the Millicast iOS SDK.
 */
@main
struct RTSViewer: App {

    var body: some Scene {
        WindowGroup {
            #if os(tvOS)
            ContentView()
                .preferredColorScheme(.dark)
            #else
            SplashScreen()
                .preferredColorScheme(.dark)
            #endif
        }
    }
}
