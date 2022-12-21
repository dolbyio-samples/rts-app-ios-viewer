import SwiftUI

/**
 * Entry point to the Sample Application (SA) for the Millicast iOS SDK.
 */
@main
struct RTSViewer: App {
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .onChange(of: scenePhase) { phase in
            print("[MAIN][onChange] Scene:\(phase)")
        }
    }
}
