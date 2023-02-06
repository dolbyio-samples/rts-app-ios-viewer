//
//  RTSDataStoreTests.swift
//

@testable import RTSComponentKit

import Combine
import MillicastSDK
import XCTest

// swiftlint:disable type_body_length
final class RTSDataStoreTests: XCTestCase {

    private var mockVideoRenderer: MCIosVideoRenderer!
    private var mockSubscriptionManager: MockSubscriptionManager!

    private var dataStore: RTSDataStore!
    private var subscriptions: [AnyCancellable] = []

    override func setUpWithError() throws {
        try super.setUpWithError()

        mockVideoRenderer = MCIosVideoRenderer()
        mockSubscriptionManager = MockSubscriptionManager()

        dataStore = RTSDataStore(subscriptionManager: mockSubscriptionManager, videoRenderer: mockVideoRenderer)
    }

    override func tearDownWithError() throws {
        try super.tearDownWithError()

        mockVideoRenderer = nil
        mockSubscriptionManager = nil
        dataStore = nil
    }

    func testToggleAudioState() {
        // Given
        let expectation = expectation(description: "Expected to update Audio Enabled State")
        var audioEnabledStateReturned: Bool?
        dataStore.$isAudioEnabled
            .dropFirst()
            .sink { audioEnabled in
                audioEnabledStateReturned = audioEnabled
                expectation.fulfill()
            }
            .store(in: &subscriptions)

        // When
        dataStore.toggleAudioState()

        waitForExpectations(timeout: 2.0)

        // Then
        XCTAssertEqual(audioEnabledStateReturned, false)
    }

    func testSetAudioEnabledToTrue() {
        // Given
        let expectation = expectation(description: "Expected to update Audio Enabled State")
        var audioEnabledStateReturned: Bool?
        dataStore.$isAudioEnabled
            .dropFirst()
            .sink { audioEnabled in
                audioEnabledStateReturned = audioEnabled
                expectation.fulfill()
            }
            .store(in: &subscriptions)

        // When
        dataStore.setAudio(true)

        waitForExpectations(timeout: 2.0)

        // Then
        XCTAssertEqual(audioEnabledStateReturned, true)
    }

    func testSetAudioEnabledToFalse() {
        // Given
        let expectation = expectation(description: "Expected to update Audio Enabled State")
        var audioEnabledStateReturned: Bool?
        dataStore.$isAudioEnabled
            .dropFirst()
            .sink { audioEnabled in
                audioEnabledStateReturned = audioEnabled
                expectation.fulfill()
            }
            .store(in: &subscriptions)

        // When
        dataStore.setAudio(false)

        waitForExpectations(timeout: 2.0)

        // Then
        XCTAssertEqual(audioEnabledStateReturned, false)
    }

    func testToggleVideoState() {
        // Given
        let expectation = expectation(description: "Expected to update Video Enabled State")
        var videoEnabledStateReturned: Bool?
        dataStore.$isVideoEnabled
            .dropFirst()
            .sink { videoEnabled in
                videoEnabledStateReturned = videoEnabled
                expectation.fulfill()
            }
            .store(in: &subscriptions)

        // When
        dataStore.toggleVideoState()

        waitForExpectations(timeout: 2.0)

        // Then
        XCTAssertEqual(videoEnabledStateReturned, false)
    }

    func testSetVideoEnabledToTrue() {
        // Given
        let expectation = expectation(description: "Expected to update Video Enabled State")
        var videoEnabledStateReturned: Bool?
        dataStore.$isVideoEnabled
            .dropFirst()
            .sink { videoEnabled in
                videoEnabledStateReturned = videoEnabled
                expectation.fulfill()
            }
            .store(in: &subscriptions)

        // When
        dataStore.setVideo(true)

        waitForExpectations(timeout: 2.0)

        // Then
        XCTAssertEqual(videoEnabledStateReturned, true)
    }

    func testSetVideoEnabledToFalse() {
        // Given
        let expectation = expectation(description: "Expected to update Video Enabled State")
        var videoEnabledStateReturned: Bool?
        dataStore.$isVideoEnabled
            .dropFirst()
            .sink { videoEnabled in
                videoEnabledStateReturned = videoEnabled
                expectation.fulfill()
            }
            .store(in: &subscriptions)

        // When
        dataStore.setVideo(false)

        waitForExpectations(timeout: 2.0)

        // Then
        XCTAssertEqual(videoEnabledStateReturned, false)
    }

    func testConnectWithStreamNameAndAccountIDForSuccess() async {
        // Given
        mockSubscriptionManager.connectionSuccessStateToReturn = true

        // When
        let success = await dataStore.connect(streamName: "TestStreamName", accountID: "TestAccountID")

        // Then
        XCTAssertTrue(success)
    }

    func testConnectWithStreamNameAndAccountIDForFailure() async {
        // Given
        mockSubscriptionManager.connectionSuccessStateToReturn = false

        // When
        let success = await dataStore.connect(streamName: "TestStreamName", accountID: "TestAccountID")

        // Then
        XCTAssertFalse(success)
    }

    func testConnectWhenThereIsNoCachedCredentials() async {
        // Given
        mockSubscriptionManager.connectionSuccessStateToReturn = true

        // When
        let success = await dataStore.connect()

        // Then
        XCTAssertFalse(success)
    }

    func testConnectWhenThereIsCachedCredentials() async {
        // Given
        mockSubscriptionManager.connectionSuccessStateToReturn = true
        _ = await dataStore.connect(streamName: "TestStreamName", accountID: "TestAccountID")

        // When
        let success = await dataStore.connect()

        // Then
        XCTAssertTrue(success)
    }

    func testStartSubscribeForSuccess() async {
        // Given
        mockSubscriptionManager.startSubscriptionStateToReturn = true

        // When
        let success = await dataStore.startSubscribe()

        // Then
        XCTAssertTrue(success)
    }

    func testStartSubscribeForFailure() async {
        // Given
        mockSubscriptionManager.startSubscriptionStateToReturn = false

        // When
        let success = await dataStore.startSubscribe()

        // Then
        XCTAssertFalse(success)
    }

    func testStopSubscribeForSuccess() async {
        // Given
        mockSubscriptionManager.stopSubscriptionStateToReturn = true

        let videoStateUpdateExpectation = expectation(description: "Expected to update Video Enabled State")
        var videoEnabledStateReturned: Bool?
        dataStore.$isVideoEnabled
            .dropFirst()
            .sink { videoEnabled in
                videoEnabledStateReturned = videoEnabled
                videoStateUpdateExpectation.fulfill()
            }
            .store(in: &subscriptions)

        let audioStateUpdateExpectation = expectation(description: "Expected to update Audio Enabled State")
        var audioEnabledStateReturned: Bool?
        dataStore.$isAudioEnabled
            .dropFirst()
            .sink { audioEnabled in
                audioEnabledStateReturned = audioEnabled
                audioStateUpdateExpectation.fulfill()
            }
            .store(in: &subscriptions)

        let subscriptionStateUpdateExpectation = expectation(description: "Expected to update Subscription State")
        var subscriptionState: RTSDataStore.State?
        dataStore.$subscribeState
            .dropFirst()
            .sink { state in
                subscriptionState = state
                subscriptionStateUpdateExpectation.fulfill()
            }
            .store(in: &subscriptions)

        // When
        let success = await dataStore.stopSubscribe()

        wait(for: [videoStateUpdateExpectation, audioStateUpdateExpectation, subscriptionStateUpdateExpectation], timeout: 2.0)

        // Then
        XCTAssertTrue(success)
        XCTAssertEqual(subscriptionState, .disconnected)
        XCTAssertEqual(audioEnabledStateReturned, false)
        XCTAssertEqual(videoEnabledStateReturned, false)
    }

    func testSubscriptionView() {
        XCTAssertEqual(dataStore.subscriptionView(), mockVideoRenderer.getView())
    }

    // MARK: SubscriptionManagerDelegate implementation tests

    func testOnStreamActive() {
        // Given
        let subscriptionStateUpdateExpectation = expectation(description: "Expected to update Subscription State")
        var subscriptionState: RTSDataStore.State?
        dataStore.$subscribeState
            .dropFirst()
            .sink { state in
                subscriptionState = state
                subscriptionStateUpdateExpectation.fulfill()
            }
            .store(in: &subscriptions)

        // When
        dataStore.onStreamActive()
        waitForExpectations(timeout: 2.0)

        // Then
        XCTAssertEqual(subscriptionState, .streamActive)
    }

    func testOnStreamInactive() {
        // Given
        let subscriptionStateUpdateExpectation = expectation(description: "Expected to update Subscription State")
        var subscriptionState: RTSDataStore.State?
        dataStore.$subscribeState
            .dropFirst()
            .sink { state in
                subscriptionState = state
                subscriptionStateUpdateExpectation.fulfill()
            }
            .store(in: &subscriptions)

        // When
        dataStore.onStreamInactive()
        waitForExpectations(timeout: 2.0)

        // Then
        XCTAssertEqual(subscriptionState, .streamInactive)
    }

    func testOnStreamStopped() {
        // Given
        let subscriptionStateUpdateExpectation = expectation(description: "Expected to update Subscription State")
        var subscriptionState: RTSDataStore.State?
        dataStore.$subscribeState
            .dropFirst()
            .sink { state in
                subscriptionState = state
                subscriptionStateUpdateExpectation.fulfill()
            }
            .store(in: &subscriptions)

        let layerActiveMapUpdateExpectation = expectation(description: "Expected to update Layer active map state")
        var activeLayers: [MCLayerData]?
        dataStore.$layerActiveMap
            .dropFirst()
            .sink { layers in
                activeLayers = layers
                layerActiveMapUpdateExpectation.fulfill()
            }
            .store(in: &subscriptions)

        // When
        dataStore.onStreamStopped()
        waitForExpectations(timeout: 2.0)

        // Then
        XCTAssertEqual(subscriptionState, .streamInactive)
        XCTAssertNil(activeLayers)
    }

    func testOnSubscribed() {
        // Given
        let subscriptionStateUpdateExpectation = expectation(description: "Expected to update Subscription State")
        var subscriptionState: RTSDataStore.State?
        dataStore.$subscribeState
            .dropFirst()
            .sink { state in
                subscriptionState = state
                subscriptionStateUpdateExpectation.fulfill()
            }
            .store(in: &subscriptions)

        // When
        dataStore.onSubscribed()
        waitForExpectations(timeout: 2.0)

        // Then
        XCTAssertEqual(subscriptionState, .subscribed)
    }

    func testOnSubscribedError() {
        // Given
        let subscriptionStateUpdateExpectation = expectation(description: "Expected to update Subscription State")
        var subscriptionState: RTSDataStore.State?
        dataStore.$subscribeState
            .dropFirst()
            .sink { state in
                subscriptionState = state
                subscriptionStateUpdateExpectation.fulfill()
            }
            .store(in: &subscriptions)

        // When
        let errorMessage = "Invalid Stream Information"
        dataStore.onSubscribedError(errorMessage)
        waitForExpectations(timeout: 2.0)

        // Then
        XCTAssertEqual(subscriptionState, .error(.subscribeError(reason: errorMessage)))
    }

    func testOnVideoTrack() {
        // Given
        let expectation = expectation(description: "Expected to update Video Enabled State")
        var videoEnabledStateReturned: Bool?
        dataStore.$isVideoEnabled
            .dropFirst()
            .sink { videoEnabled in
                videoEnabledStateReturned = videoEnabled
                expectation.fulfill()
            }
            .store(in: &subscriptions)

        // When
        let mockVideoTrack = MockMCVideoTrack()
        let mockMid = "MockMid"

        dataStore.onVideoTrack(mockVideoTrack, withMid: mockMid)
        waitForExpectations(timeout: 2.0)

        // Then
        XCTAssertEqual(videoEnabledStateReturned, true)
        XCTAssertNotNil(mockVideoTrack.addedVideoRenderer)
    }

    func testOnAudioTrack() {
        // Given
        let expectation = expectation(description: "Expected to update Audio Enabled State")
        var audioEnabledStateReturned: Bool?
        dataStore.$isAudioEnabled
            .dropFirst()
            .sink { audioEnabled in
                audioEnabledStateReturned = audioEnabled
                expectation.fulfill()
            }
            .store(in: &subscriptions)

        // When
        let mockAudioTrack = MockMCAudioTrack()
        let mockMid = "MockMid"

        dataStore.onAudioTrack(mockAudioTrack, withMid: mockMid)
        waitForExpectations(timeout: 2.0)

        // Then
        XCTAssertEqual(audioEnabledStateReturned, true)
    }

    func testOnStatsReport() {
        // Given
        let expectation = expectation(description: "Expected to update Stats Data State")
        var statisticsDataReturned: StatisticsData?
        dataStore.$statisticsData
            .dropFirst()
            .sink { statsData in
                statisticsDataReturned = statsData
                expectation.fulfill()
            }
            .store(in: &subscriptions)

        // When
        let mockStatsReport = MCStatsReport.mock

        dataStore.onStatsReport(report: mockStatsReport)
        waitForExpectations(timeout: 2.0)

        // Then
        XCTAssertNotNil(statisticsDataReturned)
    }

    func testOnConnected() {
        // Given
        let subscriptionStateUpdateExpectation = expectation(description: "Expected to update Subscription State")
        var subscriptionState: RTSDataStore.State?
        dataStore.$subscribeState
            .dropFirst()
            .sink { state in
                subscriptionState = state
                subscriptionStateUpdateExpectation.fulfill()
            }
            .store(in: &subscriptions)

        // When
        dataStore.onConnected()
        waitForExpectations(timeout: 2.0)

        // Then
        XCTAssertEqual(subscriptionState, .connected)
    }

    func testOnConnectionError() {
        // Given
        let subscriptionStateUpdateExpectation = expectation(description: "Expected to update Subscription State")
        var subscriptionState: RTSDataStore.State?
        dataStore.$subscribeState
            .dropFirst()
            .sink { state in
                subscriptionState = state
                subscriptionStateUpdateExpectation.fulfill()
            }
            .store(in: &subscriptions)

        // When
        let message = "Failed to connect"
        dataStore.onConnectionError(reason: message)
        waitForExpectations(timeout: 2.0)

        // Then
        XCTAssertEqual(subscriptionState, .error(.connectError(reason: message)))
    }
}
// swiftlint:enable type_body_length
