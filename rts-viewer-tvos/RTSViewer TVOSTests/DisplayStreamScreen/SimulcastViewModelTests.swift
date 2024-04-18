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
        mockDataStore = MockRTSDataStore()
        viewModel = SimulcastViewModel(dataStore: mockDataStore)
    }

    override func tearDownWithError() throws {
        try super.tearDownWithError()
        mockDataStore = nil
        viewModel = nil
    }

    func testSetLayerWithValueHigh() async {
        // When
        await viewModel.setLayer(quality: .high)

        // Then
        XCTAssertEqual(mockDataStore.events, [
            .selectLayer(quality: .high)
        ])
    }

    func testSetLayerWithValueAuto() async {
        // When
        await viewModel.setLayer(quality: .auto)

        // Then
        XCTAssertEqual(mockDataStore.events, [
            .selectLayer(quality: .auto)
        ])
    }

}
