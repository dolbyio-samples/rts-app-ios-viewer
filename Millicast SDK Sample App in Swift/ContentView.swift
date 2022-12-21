//
//  ContentView.swift
//  Millicast SDK Sample App in Swift
//

import SwiftUI

/**
 * Menu of the pages available in this SA.
 */
struct ContentView: View {
    var mcSA = MillicastSA.getInstance()

    var body: some View {
        NavigationView {
            VStack {
#if os(iOS)
                Spacer()
                NavigationLink(destination: mcSA.getPublishView()) {
                    Text("Publish")
                }
#endif
                Spacer()
                NavigationLink(destination: mcSA.getSubscribeView()) {
                    Text("Subscribe")
                }
                Spacer()
                NavigationLink(destination: mcSA.getSettingsView()) {
                    Text("Settings")
                }
                Spacer()
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}
