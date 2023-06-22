//
//  RecentStreamButtonViewModelTests.swift
//

@testable import RTSViewer_TVOS
import XCTest

final class RecentStreamButtonViewModelTests: XCTestCase {

    func testButtonText() throws {
        let viewModel = RecentStreamButtonViewModel(streamName: "StreamName", accountID: "AccountID")
        XCTAssertEqual(viewModel.buttonText, "StreamName / AccountID")
    }
}
