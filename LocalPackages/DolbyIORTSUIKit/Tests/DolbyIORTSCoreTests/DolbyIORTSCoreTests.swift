@testable import DolbyIORTSCore

import MillicastSDK
import XCTest

final class DolbyIORTSCoreTests: XCTestCase {

    func testStreamSettings() {
        var settings = StreamSettings()

        XCTAssertEqual(settings.showSourceLabels, true)
        XCTAssertEqual(settings.multiviewLayout, StreamSettings.MultiviewLayout.list)
        XCTAssertEqual(settings.streamSortOrder, StreamSettings.StreamSortOrder.connectionOrder)
        XCTAssertEqual(settings.audioSelection, StreamSettings.AudioSelection.firstSource)

        settings = StreamSettings(showSourceLabels: false,
                                  multiviewLayout: .single,
                                  streamSortOrder: .alphaNumeric,
                                  audioSelection: .source(sourceId: "CAM-1"))

        XCTAssertEqual(settings.showSourceLabels, false)
        XCTAssertEqual(settings.multiviewLayout, StreamSettings.MultiviewLayout.single)
        XCTAssertEqual(settings.streamSortOrder, StreamSettings.StreamSortOrder.alphaNumeric)
        XCTAssertEqual(settings.audioSelection, StreamSettings.AudioSelection.source(sourceId: "CAM-1"))
    }

    func testSettingDictionary() {
        // Write/Read global settings
        var expectedSettings = StreamSettings()
        var expectedDict: [String: StreamSettings] =
        [SettingsDictionary.GlobalStreamId: expectedSettings]

        do {
            try SettingsDictionary.saveDictionary(dictionary: expectedDict)
            var restoredDict: [String: StreamSettings]
            restoredDict = try SettingsDictionary.getDictionary()

            if let restoredSettings = restoredDict[SettingsDictionary.GlobalStreamId] {
                XCTAssertEqual(restoredSettings.showSourceLabels, restoredSettings.showSourceLabels)
                XCTAssertEqual(restoredSettings.multiviewLayout, restoredSettings.multiviewLayout)
                XCTAssertEqual(restoredSettings.streamSortOrder, restoredSettings.streamSortOrder)
                XCTAssertEqual(restoredSettings.audioSelection, restoredSettings.audioSelection)
            } else {
                XCTFail("Failed to read settings for key:\(SettingsDictionary.GlobalStreamId)")
            }

            // Add/write a new settings and read it
            let expectedDictKey = "VIDEO-1"
            expectedSettings = StreamSettings(showSourceLabels: false,
                                              multiviewLayout: .single,
                                              streamSortOrder: .alphaNumeric,
                                              audioSelection: .source(sourceId: "CAM-1"))
            expectedDict[expectedDictKey] = expectedSettings

            try SettingsDictionary.saveDictionary(dictionary: expectedDict)
            restoredDict = try SettingsDictionary.getDictionary()

            if let restoredSettings = restoredDict[expectedDictKey] {
                XCTAssertEqual(restoredSettings.showSourceLabels, restoredSettings.showSourceLabels)
                XCTAssertEqual(restoredSettings.multiviewLayout, restoredSettings.multiviewLayout)
                XCTAssertEqual(restoredSettings.streamSortOrder, restoredSettings.streamSortOrder)
                XCTAssertEqual(restoredSettings.audioSelection, restoredSettings.audioSelection)
            } else {
                XCTFail("Failed to read settings for key:\(expectedDictKey)")
            }
        } catch {
            XCTFail("testSettingDiction failed")
        }
    }
}
