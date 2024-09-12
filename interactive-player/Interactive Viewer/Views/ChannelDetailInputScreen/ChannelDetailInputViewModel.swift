//
//  ChannelDetailInputViewModel.swift
//  Interactive Player
//

import Combine
import Foundation
import MillicastSDK
import RTSCore
import SwiftUI

@MainActor
final class ChannelDetailInputViewModel: ObservableObject {
    @Binding private var channels: [Channel]?
    @Binding private var showChannelView: Bool
    @Published var streamName1: String = "game"
    @Published var accountID1: String = "7csQUs"
    @Published var streamName2: String = "multiview"
    @Published var accountID2: String = "k9Mwad"
    @Published var streamName3: String = ""
    @Published var accountID3: String = ""
    @Published var streamName4: String = ""
    @Published var accountID4: String = ""
    @Published var validationError: ValidationError?
    @Published var showAlert = false

    private let streamDataManager: StreamDataManagerProtocol
    private let dateProvider: DateProvider
    private let api = SubscriptionConfiguration.Constants.productionSubscribeURL
    private let videoJitterMinimumDelayInMs = UInt(SubscriptionConfiguration.Constants.jitterMinimumDelayMs)
    private let minPlayoutDelay = UInt(SubscriptionConfiguration.Constants.playoutDelay.minimum)
    private let maxPlayoutDelay = UInt(SubscriptionConfiguration.Constants.playoutDelay.maximum)
    private let maxBitrate: UInt = .init(SubscriptionConfiguration.Constants.maxBitrate)
    private let duration = SubscriptionConfiguration.Constants.bweMonitorDurationUs
    private let waitTime = SubscriptionConfiguration.Constants.upwardsLayerWaitTimeMs
    private let forceSmooth: Bool = SubscriptionConfiguration.Constants.forceSmooth
    private let monitorDurationString: String = "\(SubscriptionConfiguration.Constants.bweMonitorDurationUs)"
    private let rateChangePercentage: Float = SubscriptionConfiguration.Constants.bweRateChangePercentage
    private let upwardsLayerWaitTimeString: String = "\(SubscriptionConfiguration.Constants.upwardsLayerWaitTimeMs)"

    init(
        channels: Binding<[Channel]?>,
        showChannelView: Binding<Bool>,
        streamDataManager: StreamDataManagerProtocol = StreamDataManager.shared,
        dateProvider: DateProvider = DefaultDateProvider()
    ) {
        self._channels = channels
        self._showChannelView = showChannelView
        self.streamDataManager = streamDataManager
        self.dateProvider = dateProvider
    }

    func playButtonPressed() {
        var confirmedChannels = [Channel]()
        let streamDetails = createStreamDetailArray()
        for detail in streamDetails {
            guard let channel = setupChannel(for: detail) else { return }
            confirmedChannels.append(channel)
        }

        channels = confirmedChannels
        showChannelView = true
    }

    func clearAllStreams() {
        streamDataManager.clearAllStreams()
    }
}

private extension ChannelDetailInputViewModel {
    func createStreamDetailArray() -> [StreamDetail] {
        var streamDetails = [StreamDetail]()
        if !streamName1.isEmpty, !accountID1.isEmpty {
            let streamDetail = StreamDetail(streamName: streamName1, accountID: accountID1)
            streamDetails.append(streamDetail)
        }
        if !streamName2.isEmpty, !accountID2.isEmpty {
            let streamDetail = StreamDetail(streamName: streamName2, accountID: accountID2)
            streamDetails.append(streamDetail)
        }
        if !streamName3.isEmpty, !accountID3.isEmpty {
            let streamDetail = StreamDetail(streamName: streamName3, accountID: accountID3)
            streamDetails.append(streamDetail)
        }
        if !streamName4.isEmpty, !accountID4.isEmpty {
            let streamDetail = StreamDetail(streamName: streamName4, accountID: accountID4)
            streamDetails.append(streamDetail)
        }
        return streamDetails
    }

    func setupChannel(for streamDetail: StreamDetail) -> Channel? {
        let success = validateAndSaveStream(
            streamName: streamDetail.streamName,
            accountID: streamDetail.accountID,
            subscribeAPI: api,
            videoJitterMinimumDelayInMs: videoJitterMinimumDelayInMs,
            minPlayoutDelay: minPlayoutDelay,
            maxPlayoutDelay: maxPlayoutDelay,
            maxBitrate: maxBitrate,
            forceSmooth: forceSmooth,
            monitorDuration: duration,
            rateChangePercentage: rateChangePercentage,
            upwardLayerWaitTime: waitTime,
            disableAudio: false,
            primaryVideoQuality: .auto,
            saveLogs: false,
            persistStream: true
        )

        guard success else { return nil }

        let configuration = configuration(
            subscribeAPI: api,
            videoJitterMinimumDelayInMs: videoJitterMinimumDelayInMs,
            minPlayoutDelay: minPlayoutDelay,
            maxPlayoutDelay: maxPlayoutDelay,
            maxBitrate: maxBitrate,
            disableAudio: false,
            primaryVideoQuality: .auto,
            saveLogs: false
        )

        let subscriptionManager1 = SubscriptionManager()
        return Channel(
            streamDetail: streamDetail,
            listViewPrimaryVideoQuality: .auto,
            configuration: configuration,
            subscriptionManager: subscriptionManager1,
            videoTracksManager: VideoTracksManager(subscriptionManager: subscriptionManager1)
        )
    }

    // swiftlint:disable function_parameter_count
    func validateAndSaveStream(
        streamName: String,
        accountID: String,
        subscribeAPI: String,
        videoJitterMinimumDelayInMs: UInt,
        minPlayoutDelay: UInt,
        maxPlayoutDelay: UInt,
        maxBitrate: UInt,
        forceSmooth: Bool,
        monitorDuration: UInt,
        rateChangePercentage: Float,
        upwardLayerWaitTime: UInt,
        disableAudio: Bool,
        primaryVideoQuality: VideoQuality,
        saveLogs: Bool,
        persistStream: Bool
    ) -> Bool {
        guard !streamName.isEmpty, !accountID.isEmpty else {
            validationError = .emptyStreamNameOrAccountID
            return false
        }
        // TODO: Need to set up persistance on channels
        if persistStream {
            streamDataManager.saveStream(
                SavedStreamDetail(
                    accountID: accountID,
                    streamName: streamName,
                    subscribeAPI: subscribeAPI,
                    videoJitterMinimumDelayInMs: videoJitterMinimumDelayInMs,
                    minPlayoutDelay: minPlayoutDelay,
                    maxPlayoutDelay: maxPlayoutDelay,
                    disableAudio: disableAudio,
                    primaryVideoQuality: primaryVideoQuality,
                    maxBitrate: maxBitrate,
                    forceSmooth: forceSmooth,
                    monitorDuration: monitorDuration,
                    rateChangePercentage: rateChangePercentage,
                    upwardsLayerWaitTimeMs: upwardLayerWaitTime,
                    saveLogs: saveLogs
                )
            )
        }
        return true
    }

    func configuration(
        subscribeAPI: String,
        videoJitterMinimumDelayInMs: UInt,
        minPlayoutDelay: UInt?,
        maxPlayoutDelay: UInt?,
        maxBitrate: UInt,
        disableAudio: Bool,
        primaryVideoQuality: VideoQuality,
        saveLogs: Bool
    ) -> SubscriptionConfiguration {
        var playoutDelay: MCForcePlayoutDelay = SubscriptionConfiguration.Constants.playoutDelay
        if let minPlayoutDelay, let maxPlayoutDelay {
            playoutDelay = MCForcePlayoutDelay(min: Int32(minPlayoutDelay), max: Int32(maxPlayoutDelay))
        }
        let currentDate = dateProvider.now
        let rtcLogPath = saveLogs ? URL.rtcLogPath(for: currentDate) : nil
        let sdkLogPath = saveLogs ? URL.sdkLogPath(for: currentDate) : nil

        return SubscriptionConfiguration(
            subscribeAPI: subscribeAPI,
            jitterMinimumDelayMs: videoJitterMinimumDelayInMs,
            maxBitrate: maxBitrate,
            disableAudio: disableAudio,
            rtcEventLogPath: rtcLogPath?.path,
            sdkLogPath: sdkLogPath?.path,
            playoutDelay: playoutDelay
        )
    }

    // swiftlint:enable function_parameter_count
}
