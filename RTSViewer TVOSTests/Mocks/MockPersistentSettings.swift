//
//  MockPersistentSettings.swift
//

@testable import RTSViewer_TVOS

import Foundation

final class MockPersistentSettings: PersistentSettingsProtocol {

    enum Event: Equatable {
        case getLiveIndicator
        case setLiveIndicator
    }
    private(set) var events: [Event] = []

    private var liveIndicatorToReturn: Bool = true
    var liveIndicatorEnabled: Bool {
        get {
            events.append(.getLiveIndicator)
            return liveIndicatorToReturn
        } set {
            events.append(.setLiveIndicator)
            liveIndicatorToReturn = newValue
        }
    }
}
