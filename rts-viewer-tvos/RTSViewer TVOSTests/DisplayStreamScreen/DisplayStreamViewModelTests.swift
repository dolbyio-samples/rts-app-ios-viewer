//
//  DisplayStreamViewModelTests.swift
//

@testable import RTSViewer_TVOS
@testable import RTSComponentKit

import Combine
import MillicastSDK
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
            .dropFirst(1) // Dropping the first two values published from the default value in the ViewModel and the data store's default
            .sink { active in
                streamActiveStateReturned = active
                expectation.fulfill()
            }
            .store(in: &subscriptions)

        XCTAssertFalse(viewModel.isStreamActive)

        // When
        mockDataStore.state = .subscribed(state: .init(mainVideoTrack: MCRTSRemoteVideoTrack()))
        waitForExpectations(timeout: 2.0)

        // Then
        XCTAssertTrue(streamActiveStateReturned)
    }

    func testSetLayerWithStreamTypeAuto() async throws {
        // When
        try await viewModel.setLayer(quality: .auto)

        // Then
        XCTAssertEqual(mockDataStore.events, [
            .selectLayer(quality: .auto)
        ])
    }

    func testStopSubscribe() async throws {
        // When
        try await viewModel.stopSubscribe()

        // Then
        XCTAssertEqual(mockDataStore.events, [
            .stopSubscribe
        ])
    }
}
