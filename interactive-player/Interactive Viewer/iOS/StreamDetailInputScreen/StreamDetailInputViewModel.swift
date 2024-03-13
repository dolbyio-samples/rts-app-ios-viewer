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

        let configuration = SubscriptionConfiguration(
            useDevelopmentServer: useDevelopmentServer,
            videoJitterMinimumDelayInMs: videoJitterMinimumDelayInMs,
            noPlayoutDelay: noPlayoutDelay,
            disableAudio: disableAudio,
            rtcEventLogPath: rtcLogPath?.path,
            sdkLogPath: sdkLogPath?.path
        )

        Task { @StreamOrchestrator [weak self] in
            guard let self = self else { return }
            _ = try await streamOrchestrator.connect(
                streamName: streamName,
                accountID: accountID,
                configuration: configuration
            )

            if saveStream {
                self.streamDataManager.saveStream(
                    .init(
                        accountID: accountID,
                        streamName: streamName,
                        useDevelopmentServer: useDevelopmentServer,
                        videoJitterMinimumDelayInMs: videoJitterMinimumDelayInMs,
                        noPlayoutDelay: noPlayoutDelay,
                        disableAudio: disableAudio,
                        primaryVideoQuality: primaryVideoQuality,
                        saveLogs: saveLogs
                    )
                )
            }
        }

        return true
    }
    // swiftlint:enable function_parameter_count

    func clearAllStreams() {
        streamDataManager.clearAllStreams()
    }
}
