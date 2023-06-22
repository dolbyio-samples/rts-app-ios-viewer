//
//  ContentView.swift
//

import DolbyIOUIKit
import SwiftUI

class AppState: ObservableObject {
    // NavigationView does not provide a `popToRoot` method like UINavigationController does in UIKit.
    // The workaround adopted is to change the `rootViewID` property thats assigned to the rootView through the `id(..)` viewmodifier
    // - so, a change in the ID redraws the view hence replicates the popToRoot behaviour
    //
    // `NavigationStack` introduced in iOS 16 SDK give better options to perform a `popToRoot`
    @Published private(set) var rootViewID: UUID = .init()

    func popToRootView() {
        rootViewID = UUID()
    }
}

struct ContentView: View {

    @ObservedObject private var themeManager = ThemeManager.instance

    var body: some View {
        NavigationView {
            LandingView()
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .environmentObject(AppState())
        .environmentObject(themeManager)
        .onAppear {
            let appearance = UINavigationBarAppearance()
            appearance.shadowColor = themeManager.theme.neutral700
            appearance.backgroundColor = themeManager.theme.neutral900
            UINavigationBar.appearance().standardAppearance = appearance
            UINavigationBar.appearance().scrollEdgeAppearance = appearance
        }
    }
}
