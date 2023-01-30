//
//  PersistentSettings.swift
//

import Foundation

final class PersistentSettings: ObservableObject {

    let userDefaults: UserDefaults

    @Published var liveIndicatorEnable: Bool {
        didSet {
            userDefaults.set(liveIndicatorEnable, forKey: Keys.liveIndicatorEnable.rawValue)
        }
    }

    private enum Keys: String {
        case liveIndicatorEnable
    }

    init() {
        userDefaults = UserDefaults.init()
        liveIndicatorEnable = userDefaults.object(forKey: Keys.liveIndicatorEnable.rawValue) as? Bool ?? true
    }

    init(suiteName: String?) {
        userDefaults = UserDefaults.init(suiteName: suiteName) ?? .init()
        liveIndicatorEnable = userDefaults.object(forKey: Keys.liveIndicatorEnable.rawValue) as? Bool ?? true
    }
}
