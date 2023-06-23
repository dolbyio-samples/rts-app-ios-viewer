//
//  RecentStreamsViewModelTests.swift
//

@testable import RTSViewer_TVOS
import Combine
import XCTest

final class RecentStreamsViewModelTests: XCTestCase {

    private var mockDateProvider: MockDateProvider!
    private var mockStreamDataManager: MockStreamDataManager!
    private var viewModel: RecentStreamsViewModel!
    private var subscriptions: [AnyCancellable] = []

    override func setUpWithError() throws {
        try super.setUpWithError()
        mockDateProvider = MockDateProvider(date: Date())
        mockStreamDataManager = MockStreamDataManager(streamDetails: [], dateProvider: mockDateProvider)
        viewModel = RecentStreamsViewModel(streamDataManager: mockStreamDataManager)
    }

    override func tearDownWithError() throws {
        try super.tearDownWithError()
        mockDateProvider = nil
        mockStreamDataManager = nil
        viewModel = nil
    }

    func testStreamDetailsPublishing() {
        // Given
        XCTAssertEqual(viewModel.streamDetails.count, 0)

        // When
        mockStreamDataManager.streamDetails
            .append(
                StreamDetail(
                    id: UUID(),
                    accountID: "MockAccountID",
                    streamName: "MockStreamName",
                    lastUsedDate: Date()
                )
            )

        let expectation = expectation(description: "Receive stream details update")
        viewModel.$streamDetails
            .dropFirst(2)
            .sink { _ in
                expectation.fulfill()
            }
            .store(in: &subscriptions)

        waitForExpectations(timeout: 2.0)

        // Then
        XCTAssertEqual(viewModel.streamDetails.count, 1)
    }

    func testFetchAllStreams() throws {
        viewModel.fetchAllStreams()

        XCTAssertEqual(mockStreamDataManager.events, [.fetchStreamDetails])
    }
}
