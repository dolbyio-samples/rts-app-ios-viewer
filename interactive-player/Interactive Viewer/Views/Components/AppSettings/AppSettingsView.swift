//
//  AppSettingsView.swift
//  Interactive Player
//
//  Created by Raveendran, Aravind on 20/10/2023.
//

import SwiftUI
import DolbyIOUIKit

struct AppSettingsView: View {
    @AppConfiguration(\.showDebugFeatures) var showDebugFeatures
    @AppConfiguration(\.enablePiP) var enablePiP

    var body: some View {
        // Custom App Configurations
        Toggle(isOn: $showDebugFeatures) {
            Text(
                "app-configuration-show-debug-features-label",
                style: .titleMedium,
                font: .custom("AvenirNext-Regular", size: FontSize.body)
            )
        }

        Toggle(isOn: $enablePiP) {
            Text(
                "app-configuration-enable-pip-features-label",
                style: .titleMedium,
                font: .custom("AvenirNext-Regular", size: FontSize.body)
            )
        }
    }
}

struct AppSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        AppSettingsView()
    }
}
