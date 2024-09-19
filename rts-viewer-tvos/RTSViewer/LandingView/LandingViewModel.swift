//
//  LandingViewModel.swift
//

import Combine
import Foundation
import RTSCore

@MainActor
final class LandingViewModel: ObservableObject {
    @Published var streamName: String = ""
    @Published var accountID: String = ""
    @Published var channels: [Channel]?

    @Published var isShowingStreamingView: Bool = false
    @Published var isShowingChannelView: Bool = false
    @Published var isShowingRecentStreams: Bool = false
    @Published var isShowingErrorAlert = false
    @Published var isShowingClearStreamsAlert = false

    private let streamDataManager: StreamDataManagerProtocol

    init(streamDataManager: StreamDataManagerProtocol = StreamDataManager.shared) {
        self.streamDataManager = streamDataManager
    }

    func clearAllStreams() {
        streamDataManager.clearAllStreams()
    }

}
