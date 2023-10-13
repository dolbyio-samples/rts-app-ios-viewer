//
//  AppConfigurationScreen.swift
//  Interactive Player
//

import DolbyIOUIKit
import DolbyIORTSUIKit
import SwiftUI

struct AppConfigurationScreen: View {

    private let bodyFont = Font.custom("AvenirNext-Regular", size: FontSize.body)
    private let titleFont = Font.custom("AvenirNext-Regular", size: FontSize.title2)

    @AppConfiguration(\.showDebugFeatures) var showDebugFeatures

    var body: some View {
        ScrollView {
            VStack {
                Text(
                    "app-configuration-title",
                    font: titleFont
                )
                .padding(.bottom, Layout.spacing3x)

                HStack(spacing: Layout.spacing2x) {
                    Toggle(isOn: $showDebugFeatures) {
                        Text(
                            "app-configuration-show-debug-features-label",
                            font: bodyFont
                        )
                    }
                }
            }
            .padding()
        }
    }
}

struct AppConfigurationScreen_Previews: PreviewProvider {
    static var previews: some View {
        AppConfigurationScreen()
    }
}
