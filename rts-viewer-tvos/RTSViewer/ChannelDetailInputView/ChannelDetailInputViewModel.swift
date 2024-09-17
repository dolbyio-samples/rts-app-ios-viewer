//
//  ChannelDetailInputViewModel.swift
//

import Foundation
import SwiftUI

@MainActor
class ChannelDetailInputViewModel: ObservableObject {
    @Published var streamName1: String = ""
    @Published var accountID1: String = ""
    @Published var streamName2: String = ""
    @Published var accountID2: String = ""
    @Published var streamName3: String = ""
    @Published var accountID3: String = ""
    @Published var streamName4: String = ""
    @Published var accountID4: String = ""
    @Binding var isShowingChannelView: Bool

    let onPlayTapped: () -> Void

    init(isShowingChannelView: Binding<Bool>, onPlayTapped: @escaping () -> Void) {
        self._isShowingChannelView = isShowingChannelView
        self.onPlayTapped = onPlayTapped
    }
}
