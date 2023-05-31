//
//  StatsInfoButton.swift
//

import DolbyIORTSCore
import DolbyIOUIKit
import SwiftUI

struct StatsInfoButton: View {

    @StateObject private var viewModel: StatsInfoViewModel

    init(streamSource: StreamSource) {
        _viewModel = StateObject(wrappedValue: StatsInfoViewModel(streamSource: streamSource))
    }

    var body: some View {
        IconButton(
            name: .info
        ) {
            // TODO: Handle as part of status info screen ticket
        }
    }
}

struct SettingsButton: View {

    var body: some View {
        IconButton(name: .settings, action: {
            // TODO: Handle as part of status info screen ticket
        }).scaleEffect(0.5, anchor: .trailing)
    }
}
