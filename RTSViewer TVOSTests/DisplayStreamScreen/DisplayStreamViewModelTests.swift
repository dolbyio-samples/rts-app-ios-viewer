//
//  DisplayStreamViewModelTests.swift
//

@testable import RTSViewer_TVOS

import Combine
import MillicastSDK
import RTSComponentKit
import XCTest

final class DisplayStreamViewModelTests: XCTestCase {

    private var mockDataStore: MockRTSDataStore!
    private var mockPersistentSettings: MockPersistentSettings!
    private var mockNetworkMonitor: MockNetworkMonitor!

    private var viewModel: DisplayStreamViewModel!
    private var subscriptions: [AnyCancellable] = []

    override func setUpWithError() throws {
        try super.setUpWithError()

        mockDataStore = MockRTSDataStore()
        mockPersistentSettings = MockPersistentSettings()
        mockNetworkMonitor = MockNetworkMonitor()
        mockNetworkMonitor.networkStatusToReturn = true

        viewModel = DisplayStreamViewModel(
            dataStore: mockDataStore,
            persistentSettings: mockPersistentSettings,
            networkMonitor: mockNetworkMonitor
        )
    }

    override func tearDownWithError() throws {
        try super.tearDownWithError()

        mockDataStore = nil
        mockPersistentSettings = nil
        mockNetworkMonitor = nil

        viewModel = nil
    }

    func testSubscribeStateChangesForStreamActive() {
        // Given
        let expectation = expectation(description: "Wait for Stream Subscription State Update")
        var streamActiveStateReturned = false
        viewModel.$isStreamActive
            .dropFirst(2) // Dropping the first two values published from the default value in the ViewModel and the data store's default
            .sink { active in
                streamActiveStateReturned = active
                expectation.fulfill()
            }
            .store(in: &subscriptions)

        XCTAssertFalse(viewModel.isStreamActive)

        // When
        mockDataStore.subscribeState = .streamActive
        waitForExpectations(timeout: 2.0)

        // Then
        XCTAssertTrue(streamActiveStateReturned)
    }

    func testStreamingView() {
        // Given
        mockDataStore.subscriptionViewToReturn = UIView()

        // When & Then
        XCTAssertNotNil(viewModel.streamingView)
    }

    func testSetLayerWithStreamTypeAuto() {
        // When
        viewModel.setLayer(streamType: .auto)

        // Then
        XCTAssertEqual(mockDataStore.events, [
            .selectLayer(streamType: .auto)
        ])
    }

    func testStopSubscribe() async {
        // When
        await viewModel.stopSubscribe()

        // Then
        XCTAssertEqual(mockDataStore.events, [
            .stopSubscribe
        ])
    }
}
