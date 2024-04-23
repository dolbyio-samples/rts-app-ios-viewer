//
//  SettingsManagerTests.swift
//

@testable import DolbyIORTSUIKit
import XCTest

final class SettingsManagerTests: XCTestCase {

    func testSettingsManagerDefaultSettingsForGlobal() throws {
        let expectation = self.expectation(description: "Expected to return settings")
        let manager = SettingsManager.shared

        var settingsReturned: StreamSettings?
        let subscription = manager.publisher(for: .global)
            .sink { settings in
                settingsReturned = settings
                expectation.fulfill()
            }

        wait(for: [expectation], timeout: 2.0)

        let settings = try XCTUnwrap(settingsReturned)
        XCTAssertEqual(settings.audioSelection, .firstSource)
        XCTAssertEqual(settings.audioSources, [])
        XCTAssertEqual(settings.multiviewLayout, .list)
        XCTAssertTrue(settings.showSourceLabels)
        XCTAssertEqual(settings.streamSortOrder, .connectionOrder)

        subscription.cancel()
    }

    func testSettingsManagerDefaultSettingsForStream() throws {
        let expectation = self.expectation(description: "Expected to return settings")
        let manager = SettingsManager.shared

        var settingsReturned: StreamSettings?
        let subscription = manager.publisher(for: .stream(streamName: "ABC", accountID: "123"))
            .sink { settings in
                settingsReturned = settings
                expectation.fulfill()
            }

        wait(for: [expectation], timeout: 2.0)

        let settings = try XCTUnwrap(settingsReturned)
        XCTAssertEqual(settings.audioSelection, .firstSource)
        XCTAssertEqual(settings.audioSources, [])
        XCTAssertEqual(settings.multiviewLayout, .list)
        XCTAssertTrue(settings.showSourceLabels)
        XCTAssertEqual(settings.streamSortOrder, .connectionOrder)

        subscription.cancel()
    }
}
