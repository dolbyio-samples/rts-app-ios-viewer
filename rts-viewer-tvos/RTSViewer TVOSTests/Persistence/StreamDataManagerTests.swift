//
//  StreamDataManagerTests.swift
//

@testable import RTSViewer_TVOS
import Combine
import XCTest

final class StreamDataManagerTests: XCTestCase {

    private var mockDate: Date!
    private var dataManager: StreamDataManager!
    private var mockDateProvider: MockDateProvider!
    private var subscriptions: [AnyCancellable] = []

    override func setUpWithError() throws {
        try super.setUpWithError()

        self.mockDate = Date()
        self.mockDateProvider = MockDateProvider(date: mockDate)
        self.dataManager = StreamDataManager(type: .testing, dateProvider: mockDateProvider)
    }

    override func tearDownWithError() throws {
        try super.tearDownWithError()

        self.mockDate = nil
        self.mockDateProvider = nil
        self.dataManager = nil
    }

    func testFetchStreamDetailsWhenThereAreNoStreamDetails() {
        // Given
        let expectation = self.expectation(description: "Stream Details Retrieval")

        // When
        dataManager.fetchStreamDetails()

        // Then
        var streamDetailsRetrieved: [StreamDetail]?
        dataManager.streamDetailsSubject
            .sink { streamDetails in
                streamDetailsRetrieved = streamDetails
                expectation.fulfill()
            }
            .store(in: &subscriptions)

        waitForExpectations(timeout: 2.0)
        XCTAssertNotNil(streamDetailsRetrieved)
        XCTAssertEqual(streamDetailsRetrieved?.count, 0)
    }

    func testFetchStreamDetailsWhenThereAreStreamDetails() throws {
        // Given
        let expectation = self.expectation(description: "Stream Details Retrieval")
        dataManager.fetchStreamDetails()

        // When
        dataManager.saveStream("TestStreamName", accountID: "TestAccountID")

        // Then
        var streamDetailsRetrieved: [StreamDetail]?
        dataManager.streamDetailsSubject
            .sink { streamDetails in
                streamDetailsRetrieved = streamDetails
                expectation.fulfill()
            }
            .store(in: &subscriptions)

        waitForExpectations(timeout: 2.0)

        XCTAssertEqual(streamDetailsRetrieved?.count, 1)

        let firstStreamDetail = try XCTUnwrap(streamDetailsRetrieved?.first)
        XCTAssertEqual(firstStreamDetail.streamName, "TestStreamName")
        XCTAssertEqual(firstStreamDetail.accountID, "TestAccountID")
    }

    func testUpdateLastUsedDate() throws {
        // Given
        let expectation = self.expectation(description: "Stream Details Retrieval")
        dataManager.fetchStreamDetails()
        dataManager.saveStream("TestStreamName", accountID: "TestAccountID")
        var savedStreamDetails: [StreamDetail]?
        let subscription = dataManager.streamDetailsSubject
            .sink { streamDetails in
                savedStreamDetails = streamDetails
                expectation.fulfill()
            }

        waitForExpectations(timeout: 2.0)
        subscription.cancel()

        let firstStreamDetail = try XCTUnwrap(savedStreamDetails?.first)

        // When
        let updateMockDate = Date()
        mockDateProvider.dateToReturn = updateMockDate
        dataManager.updateLastUsedDate(for: firstStreamDetail)

        // Then
        let refreshStreamsExpectation = self.expectation(description: "Stream Details Refreshed")
        dataManager.streamDetailsSubject
            .sink { streamDetails in
                savedStreamDetails = streamDetails
                refreshStreamsExpectation.fulfill()
            }
            .store(in: &subscriptions)

        waitForExpectations(timeout: 2.0)

        let updatedStreamDetail = try XCTUnwrap(savedStreamDetails?.first)

        XCTAssertEqual(updatedStreamDetail.streamName, "TestStreamName")
        XCTAssertEqual(updatedStreamDetail.accountID, "TestAccountID")
        XCTAssertEqual(updatedStreamDetail.lastUsedDate, updateMockDate)
    }

    func testDeleteStreamDetail() throws {
        // Given
        let expectation = self.expectation(description: "Stream Details Retrieval")
        dataManager.fetchStreamDetails()
        dataManager.saveStream("TestStreamName", accountID: "TestAccountID")
        var savedStreamDetails: [StreamDetail]?
        let subscription = dataManager.streamDetailsSubject
            .sink { streamDetails in
                savedStreamDetails = streamDetails
                expectation.fulfill()
            }

        waitForExpectations(timeout: 2.0)
        subscription.cancel()

        let firstStreamDetail = try XCTUnwrap(savedStreamDetails?.first)

        // When
        dataManager.delete(streamDetail: firstStreamDetail)

        // Then
        let refreshStreamsExpectation = self.expectation(description: "Stream Details Refreshed")
        dataManager.streamDetailsSubject
            .sink { streamDetails in
                savedStreamDetails = streamDetails
                refreshStreamsExpectation.fulfill()
            }
            .store(in: &subscriptions)

        waitForExpectations(timeout: 2.0)

        XCTAssertEqual(savedStreamDetails?.isEmpty, true)
    }

    func testSaveStream() throws {
        // Given
        let expectation = self.expectation(description: "Stream Details Retrieval")
        dataManager.fetchStreamDetails()

        // When
        dataManager.saveStream("TestStreamName", accountID: "TestAccountID")
        var savedStreamDetails: [StreamDetail]?
        dataManager.streamDetailsSubject
            .sink { streamDetails in
                savedStreamDetails = streamDetails
                expectation.fulfill()
            }
            .store(in: &subscriptions)

        waitForExpectations(timeout: 2.0)

        // Then
        let updatedStreamDetail = try XCTUnwrap(savedStreamDetails?.first)

        XCTAssertEqual(updatedStreamDetail.streamName, "TestStreamName")
        XCTAssertEqual(updatedStreamDetail.accountID, "TestAccountID")
        XCTAssertEqual(updatedStreamDetail.lastUsedDate, mockDate)
    }

    func testClearAllStreams() throws {
        // Given
        let expectation = self.expectation(description: "Stream Details Retrieval")
        dataManager.fetchStreamDetails()
        dataManager.saveStream("TestStreamName", accountID: "TestAccountID")

        // When
        dataManager.clearAllStreams()

        var streamDetailsRetrieved: [StreamDetail]?
        dataManager.streamDetailsSubject
            .sink { streamDetails in
                streamDetailsRetrieved = streamDetails
                expectation.fulfill()
            }
            .store(in: &subscriptions)

        waitForExpectations(timeout: 2.0)

        // Then
        XCTAssertNotNil(streamDetailsRetrieved)
        XCTAssertEqual(streamDetailsRetrieved?.count, 0)
    }
}
