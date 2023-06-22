//
//  PersistentSettings.swift
//

import Foundation

protocol PersistentSettingsProtocol: AnyObject {
    var liveIndicatorEnabled: Bool { get set }
}

final class PersistentSettings: PersistentSettingsProtocol {

    private let userDefaults: UserDefaults

    private enum Keys: String {
        case liveIndicatorEnabled
    }

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        liveIndicatorEnabled = userDefaults.object(forKey: Keys.liveIndicatorEnabled.rawValue) as? Bool ?? true
    }

    var liveIndicatorEnabled: Bool {
        get {
            userDefaults.object(forKey: Keys.liveIndicatorEnabled.rawValue) as? Bool ?? true
        }
        set {
            userDefaults.set(newValue, forKey: Keys.liveIndicatorEnabled.rawValue)
        }
    }
}
