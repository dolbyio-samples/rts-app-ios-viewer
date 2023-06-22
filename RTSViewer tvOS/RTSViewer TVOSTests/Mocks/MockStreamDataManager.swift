//
//  MockStreamDataManager.swift
//

@testable import RTSViewer_TVOS
import Combine
import Foundation

final class MockStreamDataManager: StreamDataManagerProtocol {

    enum Event: Equatable {
        case fetchStreamDetails
        case updateLastUsedDate(streamDetail: StreamDetail)
        case delete(streamDetail: StreamDetail)
        case saveStream(streamName: String, accountID: String)
        case clearAllStreams
    }

    private(set) var events: [Event] = []

    private(set) var streamDetailsSubject: CurrentValueSubject<[StreamDetail], Never> = .init([])
    private let dateProvider: MockDateProvider

    var streamDetails: [StreamDetail] {
        didSet {
            streamDetailsSubject.send(streamDetails)
        }
    }

    init(streamDetails: [StreamDetail], dateProvider: MockDateProvider) {
        self.streamDetails = streamDetails
        self.dateProvider = dateProvider
    }

    func fetchStreamDetails() {
        events.append(.fetchStreamDetails)
    }

    func updateLastUsedDate(for streamDetail: StreamDetail) {
        guard let firstMatchingIndex = streamDetails.firstIndex(where: { $0.streamName == streamDetail.streamName && $0.accountID == streamDetail.accountID }) else {
            fatalError("Stream Detail does not exists")
        }
        let matchingStreamDetail = streamDetails[firstMatchingIndex]

        streamDetails.remove(at: firstMatchingIndex)
        streamDetails.insert(
            .init(
                id: matchingStreamDetail.id,
                accountID: matchingStreamDetail.accountID,
                streamName: matchingStreamDetail.streamName,
                lastUsedDate: dateProvider.now
            ),
            at: firstMatchingIndex
        )

        events.append(.updateLastUsedDate(streamDetail: streamDetail))
    }

    func delete(streamDetail: RTSViewer_TVOS.StreamDetail) {
        guard let firstMatchingIndex = streamDetails.firstIndex(where: { $0.streamName == streamDetail.streamName && $0.accountID == streamDetail.accountID }) else {
            fatalError("Stream Detail does not exists")
        }
        let matchingStreamDetail = streamDetails[firstMatchingIndex]

        streamDetails.remove(at: firstMatchingIndex)
        events.append(.delete(streamDetail: streamDetail))
    }

    func saveStream(_ streamName: String, accountID: String) {
        defer {
            events.append(.saveStream(streamName: streamName, accountID: accountID))
        }

        guard let firstMatchingIndex = streamDetails.firstIndex(where: { $0.streamName == streamName && $0.accountID == accountID }) else {
            streamDetails.append(
                .init(
                    id: UUID(),
                    accountID: streamName,
                    streamName: accountID,
                    lastUsedDate: dateProvider.now
                )
            )
            return
        }

        let matchingStreamDetail = streamDetails[firstMatchingIndex]
        streamDetails.remove(at: firstMatchingIndex)
        streamDetails.insert(
            .init(
                id: matchingStreamDetail.id,
                accountID: matchingStreamDetail.accountID,
                streamName: matchingStreamDetail.streamName,
                lastUsedDate: dateProvider.now
            ),
            at: firstMatchingIndex
        )
    }

    func clearAllStreams() {
        streamDetails.removeAll()
        events.append(.clearAllStreams)
    }
}
