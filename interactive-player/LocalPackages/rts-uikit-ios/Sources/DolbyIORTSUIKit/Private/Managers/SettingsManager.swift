//
//  SettingsManager.swift
//

import Combine
import DolbyIORTSCore
import Foundation

public enum SettingsMode: Equatable {
    case global
    case stream(streamName: String, accountID: String)

    // Key against which `global settings` is stored in the `SettingsDictionary`
    fileprivate static let keyGlobalStreamSettings = "global"

    fileprivate var storageKey: String {
        switch self {
        case .global:
            return Self.keyGlobalStreamSettings
        case let .stream(streamName: streamName, accountID: accountID):
            return "\(streamName)-\(accountID)"
        }
    }
}

final public class SettingsManager {

    private enum Constants {
        static let keyStreamSettingsDictionary = "stream-settings"
    }

    private typealias SettingsDictionary = [String: StreamSettings]

    @UserDefaultsCodableBacked(key: Constants.keyStreamSettingsDictionary, defaultValue: [SettingsMode.keyGlobalStreamSettings: StreamSettings.default])
    private var settingsDictionary: SettingsDictionary

    public static let shared = SettingsManager()

    public func publisher(for mode: SettingsMode) -> AnyPublisher<StreamSettings, Never> {
        $settingsDictionary
            .compactMap {
                $0[mode.storageKey] ?? $0[SettingsMode.global.storageKey]
            }
            .removeDuplicates()
            .eraseToAnyPublisher()
    }

    public func removeSettings(for mode: SettingsMode) {
        settingsDictionary.removeValue(forKey: mode.storageKey)
    }

    func update(settings: StreamSettings, for mode: SettingsMode) {
        settingsDictionary[mode.storageKey] = settings
    }
}
