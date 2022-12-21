//
//  Millicast_SDK_Sample_App_in_SwiftApp.swift
//  Millicast SDK Sample App in Swift
//

import SwiftUI

/**
 * Entry point to the Sample Application (SA) for the Millicast iOS SDK.
 */
@main
struct Millicast_SDK_Sample_App_in_SwiftApp: App {
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
