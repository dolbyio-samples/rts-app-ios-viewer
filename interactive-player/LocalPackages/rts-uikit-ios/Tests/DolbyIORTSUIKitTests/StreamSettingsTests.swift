import XCTest
@testable import DolbyIORTSUIKit

final class StreamSettingsTests: XCTestCase {

    func testStreamSettingsDefault() {
        let settings = StreamSettings.default

        XCTAssertEqual(settings.showSourceLabels, true)
        XCTAssertEqual(settings.multiviewLayout, .list)
        XCTAssertEqual(settings.streamSortOrder, StreamSettings.StreamSortOrder.connectionOrder)
        XCTAssertEqual(settings.audioSelection, StreamSettings.AudioSelection.firstSource)
    }
}
