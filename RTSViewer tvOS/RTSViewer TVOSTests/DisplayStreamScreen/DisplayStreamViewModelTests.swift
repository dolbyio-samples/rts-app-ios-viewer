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

    func testAspectRatioWithoutCroppingLandscapeScreen() {
        let screenWidth: Float = 1920.0
        let screenHeight: Float = 1080.0
        viewModel.updateScreenSize(width: screenWidth, height: screenHeight)
        XCTAssertEqual(viewModel.width, 0)
        XCTAssertEqual(viewModel.height, 0)

        mockDataStore.dimensions = Dimensions(width: 720, height: 720)
        viewModel.updateScreenSize(width: screenWidth, height: screenHeight)
        XCTAssertEqual(viewModel.width, Double(screenHeight), accuracy: 1, "small squared frame width")
        XCTAssertEqual(viewModel.height, Double(screenHeight), accuracy: 1, "small squared frame height")

        mockDataStore.dimensions = Dimensions(width: 2180, height: 2180)
        viewModel.updateScreenSize(width: screenWidth, height: screenHeight)
        XCTAssertEqual(viewModel.width, Double(screenHeight), accuracy: 1, "large squared frame width")
        XCTAssertEqual(viewModel.height, Double(screenHeight), accuracy: 1, "large squared frame height")

        mockDataStore.dimensions = Dimensions(width: 1280, height: 720)
        viewModel.updateScreenSize(width: screenWidth, height: screenHeight)
        XCTAssertEqual(viewModel.width, Double(screenWidth), accuracy: 1, "small landscape frame width")
        XCTAssertEqual(viewModel.height, Double(screenHeight), accuracy: 1, "small landscape frame height")

        mockDataStore.dimensions = Dimensions(width: 3840, height: 2160)
        viewModel.updateScreenSize(width: screenWidth, height: screenHeight)
        XCTAssertEqual(viewModel.width, Double(3840 * (screenHeight / 2160)), accuracy: 1, "large landscape frame width")
        XCTAssertEqual(viewModel.height, Double(screenHeight), accuracy: 1, "large landscape frame height")

        mockDataStore.dimensions = Dimensions(width: 720, height: 1280)
        viewModel.updateScreenSize(width: screenWidth, height: screenHeight)
        XCTAssertEqual(viewModel.width, Double(720 * (screenHeight / 1280)), accuracy: 1, "small portrait frame width")
        XCTAssertEqual(viewModel.height, Double(screenHeight), accuracy: 1, "small portrait frame height")

        mockDataStore.dimensions = Dimensions(width: 1440, height: 2560)
        viewModel.updateScreenSize(width: screenWidth, height: screenHeight)
        XCTAssertEqual(viewModel.width, Double(1440 * (screenHeight / 2560)), accuracy: 1, "large portrait frame width")
        XCTAssertEqual(viewModel.height, Double(screenHeight), accuracy: 1, "large portrait frame height")
    }

    func testAspectRatioWithoutCroppingPortraitScreen() {
        let screenWidth: Float = 1080.0
        let screenHeight: Float = 1920.0
        viewModel.updateScreenSize(width: screenWidth, height: screenHeight)
        XCTAssertEqual(viewModel.width, 0)
        XCTAssertEqual(viewModel.height, 0)

        mockDataStore.dimensions = Dimensions(width: 720, height: 720)
        viewModel.updateScreenSize(width: screenWidth, height: screenHeight)
        XCTAssertEqual(viewModel.width, Double(screenWidth), accuracy: 1, "small squared frame width")
        XCTAssertEqual(viewModel.height, Double(screenWidth), accuracy: 1, "small squared frame height")

        mockDataStore.dimensions = Dimensions(width: 2180, height: 2180)
        viewModel.updateScreenSize(width: screenWidth, height: screenHeight)
        XCTAssertEqual(viewModel.width, Double(screenWidth), accuracy: 1, "large squared frame width")
        XCTAssertEqual(viewModel.height, Double(screenWidth), accuracy: 1, "large squared frame height")

        mockDataStore.dimensions = Dimensions(width: 1280, height: 720)
        viewModel.updateScreenSize(width: screenWidth, height: screenHeight)
        XCTAssertEqual(viewModel.width, Double(screenWidth), accuracy: 1, "small landscape frame width")
        XCTAssertEqual(viewModel.height, Double(720 * (screenWidth / 1280)), accuracy: 1, "small landscape frame height")

        mockDataStore.dimensions = Dimensions(width: 3840, height: 2160)
        viewModel.updateScreenSize(width: screenWidth, height: screenHeight)
        XCTAssertEqual(viewModel.width, Double(screenWidth), accuracy: 1, "large landscape frame width")
        XCTAssertEqual(viewModel.height, Double(2160 * (screenWidth / 3840)), accuracy: 1, "large landscape frame height")

        mockDataStore.dimensions = Dimensions(width: 720, height: 1280)
        viewModel.updateScreenSize(width: screenWidth, height: screenHeight)
        XCTAssertEqual(viewModel.width, Double(screenWidth), accuracy: 1, "small portrait frame width")
        XCTAssertEqual(viewModel.height, Double(1280 * (screenWidth / 720)), accuracy: 1, "small portrait frame height")

        mockDataStore.dimensions = Dimensions(width: 1440, height: 2560)
        viewModel.updateScreenSize(width: screenWidth, height: screenHeight)
        XCTAssertEqual(viewModel.width, Double(screenWidth), accuracy: 1, "large portrait frame width")
        XCTAssertEqual(viewModel.height, Double(2560 * (screenWidth / 1440)), accuracy: 1, "large portrait frame height")
    }

    func testAspectRatioWithCroppingLandscapeScreen() {
        let screenWidth: Float = 1920.0
        let screenHeight: Float = 1080.0
        viewModel.updateScreenSize(width: screenWidth, height: screenHeight)
        XCTAssertEqual(viewModel.width, 0)
        XCTAssertEqual(viewModel.height, 0)

        viewModel.showVideoInFullScreen(true)

        mockDataStore.dimensions = Dimensions(width: 720, height: 720)
        viewModel.updateScreenSize(width: screenWidth, height: screenHeight)
        XCTAssertEqual(viewModel.width, Double(screenWidth), accuracy: 1, "small squared frame width")
        XCTAssertEqual(viewModel.height, Double(screenWidth), accuracy: 1, "small squared frame height")

        mockDataStore.dimensions = Dimensions(width: 2180, height: 2180)
        viewModel.updateScreenSize(width: screenWidth, height: screenHeight)
        XCTAssertEqual(viewModel.width, Double(screenWidth), accuracy: 1, "large squared frame width")
        XCTAssertEqual(viewModel.height, Double(screenWidth), accuracy: 1, "large squared frame height")

        mockDataStore.dimensions = Dimensions(width: 1280, height: 720)
        viewModel.updateScreenSize(width: screenWidth, height: screenHeight)
        XCTAssertEqual(viewModel.width, Double(screenWidth), accuracy: 1, "small landscape frame width")
        XCTAssertEqual(viewModel.height, Double(screenHeight), accuracy: 1, "small landscape frame height")

        mockDataStore.dimensions = Dimensions(width: 3840, height: 2160)
        viewModel.updateScreenSize(width: screenWidth, height: screenHeight)
        XCTAssertEqual(viewModel.width, Double(screenWidth), accuracy: 1, "large landscape frame width")
        XCTAssertEqual(viewModel.height, Double(2160 * (screenWidth / 3840)), accuracy: 1, "large landscape frame height")

        mockDataStore.dimensions = Dimensions(width: 720, height: 1280)
        viewModel.updateScreenSize(width: screenWidth, height: screenHeight)
        XCTAssertEqual(viewModel.width, Double(screenWidth), accuracy: 1, "small portrait frame width")
        XCTAssertEqual(viewModel.height, Double(1280 * (screenWidth / 720)), accuracy: 1, "small portrait frame height")

        mockDataStore.dimensions = Dimensions(width: 1440, height: 2560)
        viewModel.updateScreenSize(width: screenWidth, height: screenHeight)
        XCTAssertEqual(viewModel.width, Double(screenWidth), accuracy: 1, "large portrait frame width")
        XCTAssertEqual(viewModel.height, Double(2560 * (screenWidth / 1440)), accuracy: 1, "large portrait frame height")
    }

    func testAspectRatioWithCroppingPortraitScreen() {
        let screenWidth: Float = 1080.0
        let screenHeight: Float = 1920.0
        viewModel.updateScreenSize(width: screenWidth, height: screenHeight)
        XCTAssertEqual(viewModel.width, 0)
        XCTAssertEqual(viewModel.height, 0)

        viewModel.showVideoInFullScreen(true)

        mockDataStore.dimensions = Dimensions(width: 2180, height: 2180)
        viewModel.updateScreenSize(width: screenWidth, height: screenHeight)
        XCTAssertEqual(viewModel.width, Double(screenHeight), accuracy: 1, "large squared frame width")
        XCTAssertEqual(viewModel.height, Double(screenHeight), accuracy: 1, "large squared frame height")

        mockDataStore.dimensions = Dimensions(width: 1280, height: 720)
        viewModel.updateScreenSize(width: screenWidth, height: screenHeight)
        XCTAssertEqual(viewModel.width, Double(1280 * (screenHeight / 720)), accuracy: 1, "small landscape frame width")
        XCTAssertEqual(viewModel.height, Double(screenHeight), accuracy: 1, "small landscape frame height")

        mockDataStore.dimensions = Dimensions(width: 3840, height: 2160)
        viewModel.updateScreenSize(width: screenWidth, height: screenHeight)
        XCTAssertEqual(viewModel.width, Double(3840 * (screenHeight / 2160)), accuracy: 1, "large landscape frame width")
        XCTAssertEqual(viewModel.height, Double(screenHeight), accuracy: 1, "large landscape frame height")

        mockDataStore.dimensions = Dimensions(width: 720, height: 1280)
        viewModel.updateScreenSize(width: screenWidth, height: screenHeight)
        XCTAssertEqual(viewModel.width, Double(screenWidth), accuracy: 1, "small portrait frame width")
        XCTAssertEqual(viewModel.height, Double(1280 * (screenWidth / 720)), accuracy: 1, "small portrait frame height")

        mockDataStore.dimensions = Dimensions(width: 1440, height: 2560)
        viewModel.updateScreenSize(width: screenWidth, height: screenHeight)
        XCTAssertEqual(viewModel.width, Double(screenWidth), accuracy: 1, "large portrait frame width")
        XCTAssertEqual(viewModel.height, Double(2560 * (screenWidth / 1440)), accuracy: 1, "large portrait frame height")
    }
}
