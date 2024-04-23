//
//  RTSDataStoreTests.swift
//

@testable import RTSComponentKit

import Combine
import MillicastSDK
import XCTest

final class RTSDataStoreTests: XCTestCase {

    private var mockSubscriptionManager: MockSubscriptionManager!

    private var dataStore: RTSDataStore!
    private var subscriptions: [AnyCancellable] = []

    override func setUpWithError() throws {
        try super.setUpWithError()

        mockSubscriptionManager = MockSubscriptionManager()
        dataStore = RTSDataStore()
    }

    override func tearDownWithError() throws {
        try super.tearDownWithError()

        mockSubscriptionManager = nil
        dataStore = nil
    }

    func testConnectWithStreamNameAndAccountIDForSuccess() async throws {
        // Given
        mockSubscriptionManager.connectionSuccessStateToReturn = true

        // When
        let success = try await dataStore.connect(streamName: "TestStreamName", accountID: "TestAccountID", subscriptionManager: mockSubscriptionManager)

        // Then
        XCTAssertTrue(success)
    }

    func testConnectWithStreamNameAndAccountIDForFailure() async throws {
        // Given
        mockSubscriptionManager.connectionSuccessStateToReturn = false

        // When
        let success = try await dataStore.connect(streamName: "TestStreamName", accountID: "TestAccountID", subscriptionManager: mockSubscriptionManager)

        // Then
        XCTAssertFalse(success)
    }

    func testStartSubscribeForSuccess() async throws {
        // Given
        mockSubscriptionManager.startSubscriptionStateToReturn = true

        // When
        _ = try await dataStore.connect(streamName: "TestStreamName", accountID: "TestAccountID", subscriptionManager: mockSubscriptionManager)
        let success = try await dataStore.startSubscribe()

        // Then
        XCTAssertTrue(success)
    }

    func testStartSubscribeForFailure() async throws {
        // Given
        mockSubscriptionManager.startSubscriptionStateToReturn = false

        // When
        _ = try await dataStore.connect(streamName: "TestStreamName", accountID: "TestAccountID", subscriptionManager: mockSubscriptionManager)
        let success = try await dataStore.startSubscribe()

        // Then
        XCTAssertFalse(success)
    }

    func testStopSubscribeForSuccess() async throws {
        // Given
        mockSubscriptionManager.stopSubscriptionStateToReturn = true

        // When
        _ = try await dataStore.connect(streamName: "TestStreamName", accountID: "TestAccountID", subscriptionManager: mockSubscriptionManager)
        let success = try await dataStore.stopSubscribe()

        // Then
        XCTAssertTrue(success)
    }

    func testOnStreamActive() async throws {
        // Given
        let subscriptionStateUpdateExpectation = expectation(description: "Expected to update Subscription State")
        var subscriptionState: RTSDataStore.State?
        dataStore.$state
            .dropFirst(2)
            .sink { state in
                subscriptionState = state
                subscriptionStateUpdateExpectation.fulfill()
            }
            .store(in: &subscriptions)

        // When
        _ = try await dataStore.connect(streamName: "TestStreamName", accountID: "TestAccountID", subscriptionManager: mockSubscriptionManager)
        let track = MCVideoTrack()
        mockSubscriptionManager.tracksContinuation.yield(.video(track: track, mid: "1"))
        mockSubscriptionManager.activityContinuation.yield(.active(streamId: "streamName/accountId", tracks: ["video", "audio"], sourceId: ""))
        await fulfillment(of: [subscriptionStateUpdateExpectation], timeout: 2.0)

        // Then
        XCTAssertEqual(subscriptionState, .subscribed(state: .init(mainVideoTrack: track)))
    }

    func testOnStreamStopped() async throws {
        // Given
        let subscriptionStateUpdateExpectation = expectation(description: "Expected to update Subscription State")
        var subscriptionState: RTSDataStore.State?
        dataStore.$state
            .dropFirst(3)
            .sink { state in
                subscriptionState = state
                subscriptionStateUpdateExpectation.fulfill()
            }
            .store(in: &subscriptions)

        // When
        _ = try await dataStore.connect(streamName: "TestStreamName", accountID: "TestAccountID", subscriptionManager: mockSubscriptionManager)

        let track = MCVideoTrack()
        mockSubscriptionManager.tracksContinuation.yield(.video(track: track, mid: "1"))
        mockSubscriptionManager.activityContinuation.yield(.active(streamId: "streamName/accountId", tracks: ["video", "audio"], sourceId: ""))
        mockSubscriptionManager.activityContinuation.yield(.inactive(streamId: "streamName/accountId", sourceId: ""))
        await fulfillment(of: [subscriptionStateUpdateExpectation], timeout: 2.0)

        // Then
        XCTAssertEqual(subscriptionState, .stopped)
    }

    func testOnSubscribedAfterStopped() async throws {
        // Given
        let subscriptionStateUpdateExpectation = expectation(description: "Expected to update Subscription State")
        var subscriptionState: RTSDataStore.State?
        dataStore.$state
            .dropFirst(4)
            .sink { state in
                subscriptionState = state
                subscriptionStateUpdateExpectation.fulfill()
            }
            .store(in: &subscriptions)

        // When
        _ = try await dataStore.connect(streamName: "TestStreamName", accountID: "TestAccountID", subscriptionManager: mockSubscriptionManager)

        let track = MCVideoTrack()
        mockSubscriptionManager.tracksContinuation.yield(.video(track: track, mid: "1"))
        mockSubscriptionManager.activityContinuation.yield(.active(streamId: "streamName/accountId", tracks: ["video", "audio"], sourceId: ""))
        mockSubscriptionManager.activityContinuation.yield(.inactive(streamId: "streamName/accountId", sourceId: ""))
        mockSubscriptionManager.activityContinuation.yield(.active(streamId: "streamName/accountId", tracks: ["video", "audio"], sourceId: ""))
        await fulfillment(of: [subscriptionStateUpdateExpectation], timeout: 2.0)

        // Then
        XCTAssertEqual(subscriptionState, .subscribed(state: .init(mainVideoTrack: track)))
    }

    func testConnectionError() async throws {
        // Given
        let subscriptionStateUpdateExpectation = expectation(description: "Expected to update Subscription State")
        var subscriptionState: RTSDataStore.State?
        dataStore.$state
            .dropFirst(1)
            .sink { state in
                subscriptionState = state
                subscriptionStateUpdateExpectation.fulfill()
            }
            .store(in: &subscriptions)

        // When
        _ = try await dataStore.connect(streamName: "TestStreamName", accountID: "TestAccountID", subscriptionManager: mockSubscriptionManager)

        mockSubscriptionManager.stateContinuation.yield(.connectionError(status: 0, reason: "some error"))
        await fulfillment(of: [subscriptionStateUpdateExpectation], timeout: 2.0)

        // Then
        XCTAssertEqual(subscriptionState, .error(.connectError(status: 0, reason: "some error")))
    }

    func testSignalingError() async throws {
        // Given
        let subscriptionStateUpdateExpectation = expectation(description: "Expected to update Subscription State")
        var subscriptionState: RTSDataStore.State?
        dataStore.$state
            .dropFirst(1)
            .sink { state in
                subscriptionState = state
                subscriptionStateUpdateExpectation.fulfill()
            }
            .store(in: &subscriptions)

        // When
        _ = try await dataStore.connect(streamName: "TestStreamName", accountID: "TestAccountID", subscriptionManager: mockSubscriptionManager)

        mockSubscriptionManager.stateContinuation.yield(.signalingError(reason: "signal error"))
        await fulfillment(of: [subscriptionStateUpdateExpectation], timeout: 2.0)

        // Then
        XCTAssertEqual(subscriptionState, .error(.signalingError(reason: "signal error")))
    }

    func testOnStatsReport() async throws {
        // Given
        let expectation = expectation(description: "Expected to update Stats Data State")
        var subscriptionState: RTSDataStore.State?
        dataStore.$state
            .dropFirst(2)
            .sink { state in
                subscriptionState = state
                expectation.fulfill()
            }
            .store(in: &subscriptions)

        // When
        _ = try await dataStore.connect(streamName: "TestStreamName", accountID: "TestAccountID", subscriptionManager: mockSubscriptionManager)

        let track = MCVideoTrack()
        mockSubscriptionManager.tracksContinuation.yield(.video(track: track, mid: "1"))

        let mockStatsReport = MCStatsReport.mock
        mockSubscriptionManager.statsReportContinuation.yield(mockStatsReport)
        await fulfillment(of: [expectation], timeout: 2.0)

        // Then
        switch subscriptionState {
        case let .subscribed(state: subscribedState):
            XCTAssertEqual(subscribedState.statisticsData, dataStore.getStatisticsData(report: mockStatsReport))
        default:
            XCTFail("Invalid state returned")
        }
    }

    func testOnConnected() async throws {
        // Given
        let subscriptionStateUpdateExpectation = expectation(description: "Expected to update Subscription State")
        var subscriptionState: RTSDataStore.State?
        dataStore.$state
            .dropFirst(1)
            .sink { state in
                subscriptionState = state
                subscriptionStateUpdateExpectation.fulfill()
            }
            .store(in: &subscriptions)

        // When
        _ = try await dataStore.connect(streamName: "TestStreamName", accountID: "TestAccountID", subscriptionManager: mockSubscriptionManager)

        mockSubscriptionManager.stateContinuation.yield(.connected)
        await fulfillment(of: [subscriptionStateUpdateExpectation], timeout: 2.0)

        // Then
        XCTAssertEqual(subscriptionState, .connected)
    }
}
