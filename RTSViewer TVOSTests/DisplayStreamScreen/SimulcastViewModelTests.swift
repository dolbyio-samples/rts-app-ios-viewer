//
//  SimulcastViewModelTests.swift
//

@testable import RTSViewer_TVOS

import MillicastSDK
import XCTest

final class SimulcastViewModelTests: XCTestCase {

    private var viewModel: SimulcastViewModel!
    private var mockDataStore: MockRTSDataStore!

    override func setUpWithError() throws {
        try super.setUpWithError()
        mockDataStore = MockRTSDataStore(videoRenderer: MCIosVideoRenderer())
        viewModel = SimulcastViewModel(dataStore: mockDataStore)
    }

    override func tearDownWithError() throws {
        try super.tearDownWithError()
        mockDataStore = nil
        viewModel = nil
    }

    func testSetLayerWithValueHigh() {
        // When
        viewModel.setLayer(streamType: .high)

        // Then
        XCTAssertEqual(mockDataStore.events, [
            .selectLayer(streamType: .high)
        ])
    }

    func testSetLayerWithValueAuto() {
        // When
        viewModel.setLayer(streamType: .auto)

        // Then
        XCTAssertEqual(mockDataStore.events, [
            .selectLayer(streamType: .auto)
        ])
    }

}
