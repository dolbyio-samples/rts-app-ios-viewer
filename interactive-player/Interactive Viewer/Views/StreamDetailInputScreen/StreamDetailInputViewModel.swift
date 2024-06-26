//
//  StreamDetailInputViewModel.swift
//

import Combine
import RTSCore
import Foundation
import MillicastSDK

@MainActor
final class StreamDetailInputViewModel: ObservableObject {
    let subscriptionManager: SubscriptionManager
    private let streamDataManager: StreamDataManagerProtocol
    private let dateProvider: DateProvider

    enum ValidationError: LocalizedError {
        case emptyStreamNameOrAccountID
        case failedToConnect

        var errorDescription: String? {
            switch self {
            case .emptyStreamNameOrAccountID:
                return String(localized: "stream-detail-input.empty-credentials-error.label")
            case .failedToConnect:
                return String(localized: "stream-detail-input.connection-failure.label")
            }
        }
    }

    @Published var validationError: ValidationError?

    init(
        subscriptionManager: SubscriptionManager = SubscriptionManager(),
        streamDataManager: StreamDataManagerProtocol = StreamDataManager.shared,
        dateProvider: DateProvider = DefaultDateProvider()
    ) {
        self.subscriptionManager = subscriptionManager
        self.streamDataManager = streamDataManager
        self.dateProvider = dateProvider
    }

    // swiftlint:disable function_parameter_count
    func connect(
        streamName: String,
        accountID: String,
        subscribeAPI: String,
        videoJitterMinimumDelayInMs: UInt,
        minPlayoutDelay: UInt?,
        maxPlayoutDelay: UInt?,
        disableAudio: Bool,
        primaryVideoQuality: VideoQuality,
        saveLogs: Bool,
        saveStream: Bool
    ) -> Bool {
        guard !streamName.isEmpty, !accountID.isEmpty else {
            validationError = .emptyStreamNameOrAccountID
            return false
        }
        let currentDate = dateProvider.now
        let rtcLogPath = saveLogs ? URL.rtcLogPath(for: currentDate) : nil
        let sdkLogPath = saveLogs ? URL.sdkLogPath(for: currentDate) : nil

        if saveStream {
            self.streamDataManager.saveStream(
                SavedStreamDetail(
                    accountID: accountID,
                    streamName: streamName,
                    subscribeAPI: subscribeAPI,
                    videoJitterMinimumDelayInMs: videoJitterMinimumDelayInMs,
                    minPlayoutDelay: minPlayoutDelay,
                    maxPlayoutDelay: maxPlayoutDelay,
                    disableAudio: disableAudio,
                    primaryVideoQuality: primaryVideoQuality,
                    saveLogs: saveLogs
                )
            )
        }

        let playoutDelay: MCForcePlayoutDelay?
        if let minPlayoutDelay, let maxPlayoutDelay {
            playoutDelay = MCForcePlayoutDelay(min: Int32(minPlayoutDelay), max: Int32(maxPlayoutDelay))
        } else {
            playoutDelay = nil
        }

        let configuration = SubscriptionConfiguration(
            subscribeAPI: subscribeAPI,
            jitterMinimumDelayMs: videoJitterMinimumDelayInMs,
            disableAudio: disableAudio,
            rtcEventLogPath: rtcLogPath?.path,
            sdkLogPath: sdkLogPath?.path,
            playoutDelay: playoutDelay
        )

        Task { [weak self] in
            guard let self = self else { return }
            _ = try await subscriptionManager.subscribe(
                streamName: streamName,
                accountID: accountID,
                configuration: configuration
            )
        }

        return true
    }
    // swiftlint:enable function_parameter_count

    func clearAllStreams() {
        streamDataManager.clearAllStreams()
    }
}
