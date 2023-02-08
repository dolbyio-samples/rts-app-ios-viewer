//
//  DisplayStreamViewModelTests.swift
//

@testable import RTSViewer_TVOS

import Combine
import MillicastSDK
import XCTest

final class DisplayStreamViewModelTests: XCTestCase {

    private var mockDataStore: MockRTSDataStore!
    private var mockPersistentSettings: MockPersistentSettings!
    private var mockNetworkMonitor: MockNetworkMonitor!

    private var viewModel: DisplayStreamViewModel!

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
