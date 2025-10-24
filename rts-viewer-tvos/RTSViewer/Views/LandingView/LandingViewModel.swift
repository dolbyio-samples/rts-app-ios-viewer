//
//  LandingViewModel.swift
//

import Combine
import Foundation
import MillicastSDK
import RTSCore

@MainActor
final class LandingViewModel: ObservableObject {
    @Published var streamName: String = ""
    @Published var accountID: String = ""
    @Published var enableDebugLogging: Bool = false
    @Published var playoutDelayMin: Int32?
    @Published var playoutDelayMax: Int32?
    @Published var unsourcedChannel: [UnsourcedChannel]?

    @Published var isShowingStreamingView: Bool = false
    @Published var isShowingChannelView: Bool = false
    @Published var isShowingRecentStreams: Bool = false
    @Published var isShowingErrorAlert = false
    @Published var isShowingClearStreamsAlert = false

    let sdkVersion = "SDK Version \(MCLogger.getVersion())"
    var appVersion: String = ""

    private let streamDataManager: StreamDataManagerProtocol

    init(streamDataManager: StreamDataManagerProtocol = StreamDataManager.shared) {
        self.streamDataManager = streamDataManager

        if let version = Bundle.main.releaseVersionNumber,
           let build = Bundle.main.buildVersionNumber {
            self.appVersion = "App Version \(version) \(build)"
        }
    }

    func clearAllStreams() {
        streamDataManager.clearAllStreams()
    }
}
