//
//  StreamDetailInputViewModel.swift
//

import Combine
import RTSCore
import Foundation
import MillicastSDK

@MainActor
final class StreamDetailInputViewModel: ObservableObject {
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
        streamDataManager: StreamDataManagerProtocol = StreamDataManager.shared,
        dateProvider: DateProvider = DefaultDateProvider()
    ) {
        self.streamDataManager = streamDataManager
        self.dateProvider = dateProvider
    }

    // swiftlint:disable function_parameter_count
    func validateAndSaveStream(
        streamName: String,
        accountID: String,
        subscribeAPI: String,
        videoJitterMinimumDelayInMs: UInt,
        minPlayoutDelay: UInt?,
        maxPlayoutDelay: UInt?,
        disableAudio: Bool,
        primaryVideoQuality: VideoQuality,
        saveLogs: Bool,
        persistStream: Bool
    ) -> Bool {
        guard !streamName.isEmpty, !accountID.isEmpty else {
            validationError = .emptyStreamNameOrAccountID
            return false
        }
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
        disableAudio: Bool,
        primaryVideoQuality: VideoQuality,
        saveLogs: Bool
    ) -> SubscriptionConfiguration {
        let playoutDelay: MCForcePlayoutDelay?
        if let minPlayoutDelay, let maxPlayoutDelay {
            playoutDelay = MCForcePlayoutDelay(min: Int32(minPlayoutDelay), max: Int32(maxPlayoutDelay))
        } else {
            playoutDelay = nil
        }
        let currentDate = dateProvider.now
        let rtcLogPath = saveLogs ? URL.rtcLogPath(for: currentDate) : nil
        let sdkLogPath = saveLogs ? URL.sdkLogPath(for: currentDate) : nil

        return SubscriptionConfiguration(
            subscribeAPI: subscribeAPI,
            jitterMinimumDelayMs: videoJitterMinimumDelayInMs,
            disableAudio: disableAudio,
            rtcEventLogPath: rtcLogPath?.path,
            sdkLogPath: sdkLogPath?.path,
            playoutDelay: playoutDelay
        )
    }
    // swiftlint:enable function_parameter_count

    func clearAllStreams() {
        streamDataManager.clearAllStreams()
    }
}
