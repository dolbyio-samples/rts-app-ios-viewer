//
//  StreamDetailInputViewModel.swift
//

import Combine
import DolbyIORTSCore
import Foundation

@MainActor
final class StreamDetailInputViewModel: ObservableObject {
    let streamOrchestrator: StreamOrchestrator
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
        streamOrchestrator: StreamOrchestrator = .shared,
        streamDataManager: StreamDataManagerProtocol = StreamDataManager.shared,
        dateProvider: DateProvider = DefaultDateProvider()
    ) {
        self.streamOrchestrator = streamOrchestrator
        self.streamDataManager = streamDataManager
        self.dateProvider = dateProvider
    }

    // swiftlint:disable function_parameter_count
    func connect(
        streamName: String,
        accountID: String,
        useDevelopmentServer: Bool,
        videoJitterMinimumDelayInMs: UInt,
        noPlayoutDelay: Bool,
        disableAudio: Bool,
        primaryVideoQuality: VideoQuality,
        shouldSave: Bool
    ) async -> Bool {
        guard !streamName.isEmpty, !accountID.isEmpty else {
            validationError = .emptyStreamNameOrAccountID
            return false
        }
        let currentDate = dateProvider.now
        let rtcLogPath = URL.rtcLogPath(for: currentDate)
        let sdkLogPath = URL.sdkLogPath(for: currentDate)

        let configuration = SubscriptionConfiguration(
            useDevelopmentServer: useDevelopmentServer,
            videoJitterMinimumDelayInMs: videoJitterMinimumDelayInMs,
            noPlayoutDelay: noPlayoutDelay,
            disableAudio: disableAudio,
            rtcEventLogPath: rtcLogPath?.path,
            sdkLogPath: sdkLogPath?.path
        )

        let success = await streamOrchestrator.connect(
            streamName: streamName,
            accountID: accountID,
            configuration: configuration
        )

        switch (success, shouldSave) {
        case (true, true):
            streamDataManager.saveStream(
                .init(
                    accountID: accountID,
                    streamName: streamName,
                    useDevelopmentServer: useDevelopmentServer,
                    videoJitterMinimumDelayInMs: videoJitterMinimumDelayInMs,
                    noPlayoutDelay: noPlayoutDelay,
                    disableAudio: disableAudio,
                    primaryVideoQuality: primaryVideoQuality
                )
            )
        case (false, _):
            validationError = .failedToConnect
        default:
            break
        }
        return success
    }
    // swiftlint:enable function_parameter_count

    func clearAllStreams() {
        streamDataManager.clearAllStreams()
    }
}
