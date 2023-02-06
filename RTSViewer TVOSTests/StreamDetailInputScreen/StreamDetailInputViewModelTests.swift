//
//  StreamDetailInputViewModelTests.swift
//

@testable import RTSViewer_TVOS

import Combine
import XCTest

final class StreamDetailInputViewModelTests: XCTestCase {

    private var mockStreamDataManager: MockStreamDataManager!
    private var mockDataStore: MockRTSDataStore!
    private var subscriptions: [AnyCancellable] = []

    private var viewModel: StreamDetailInputViewModel!

    override func setUpWithError() throws {
        try super.setUpWithError()

        mockStreamDataManager = MockStreamDataManager(streamDetails: [], dateProvider: MockDateProvider(date: Date()))
        mockDataStore = MockRTSDataStore()

        viewModel = StreamDetailInputViewModel(dataStore: mockDataStore, streamDataManager: mockStreamDataManager)
    }

    override func tearDownWithError() throws {
        try super.tearDownWithError()

        mockStreamDataManager = nil
        mockDataStore = nil

        viewModel = nil
    }

    func testSavedStreamUpdates() {
        // Given
        let expectation = expectation(description: "Saved stream details are updated")
        var streamDetailsReturned: [StreamDetail] = []
        viewModel.$streamDetails
            .dropFirst(1) // Skip the current value
            .sink { streamDetails in
                streamDetailsReturned = streamDetails
                expectation.fulfill()
            }
            .store(in: &subscriptions)
        XCTAssertEqual(streamDetailsReturned.count, 0)

        // When - trigger a saved streams update
        mockStreamDataManager.saveStream("TestStreamName", accountID: "TestAccountID")
        waitForExpectations(timeout: 2.0)

        // Then
        XCTAssertEqual(streamDetailsReturned.count, 1)
    }

    func testHasSavedStreamsUpdate() {
        // Given
        let expectation = expectation(description: "Saved stream details are updated")
        viewModel.$hasSavedStreams
            .dropFirst(1) // Skip the current value
            .sink { _ in
                expectation.fulfill()
            }
            .store(in: &subscriptions)
        XCTAssertFalse(viewModel.hasSavedStreams)

        // When - trigger a saved streams update
        mockStreamDataManager.saveStream("TestStreamName", accountID: "TestAccountID")
        waitForExpectations(timeout: 2.0)

        // Then
        XCTAssertTrue(viewModel.hasSavedStreams)
    }

    func testConnectWithStreamNameAndAccountID() async {
        // Given
        mockDataStore.connectWithCredentialsStateToReturn = true

        // When
        let success = await viewModel.connect(streamName: "TestStreamName", accountID: "TestAccountID")

        // Then
        XCTAssertTrue(success)
        XCTAssertEqual(mockDataStore.events, [
            .connectWith(streamName: "TestStreamName", accountID: "TestAccountID")
        ])
    }

    func testConnectWithStreamNameAndAccountIDForFailure() async {
        // Given
        mockDataStore.connectWithCredentialsStateToReturn = false

        // When
        let success = await viewModel.connect(streamName: "TestStreamName", accountID: "TestAccountID")

        // Then
        XCTAssertFalse(success)
    }

    func testSaveStreamWithStreamNameAndAccountID() {
        // When
        viewModel.saveStream(streamName: "TestStreamName", accountID: "TestAccountID")

        // Then
        XCTAssertEqual(mockStreamDataManager.events, [
            .saveStream(streamName: "TestStreamName", accountID: "TestAccountID")
        ])
    }

    func testClearAllStreams() {
        // When
        viewModel.clearAllStreams()

        // Then
        XCTAssertEqual(mockStreamDataManager.events, [
            .clearAllStreams
        ])
    }
}
