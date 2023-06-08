//
//  SettingsManager.swift
//

import Combine
import Foundation

open class SettingsManager {

    public enum Mode: Equatable {
        case global
        case stream(streamID: String)
    }

    public static let shared: SettingsManager = .init()
    public private(set) var mode: Mode = .global

    public var currentStreamId: String {
        switch mode {
        case .global: return SettingsDictionary.GlobalStreamId
        case .stream(let streamId): return streamId
        }
    }

    public var settings: StreamSettings {
        didSet {
            self.settingsSubject.send(settings)
            try? SettingsDictionary.saveSettings(for: currentStreamId, settings: settings)
        }
    }

    private lazy var settingsSubject: CurrentValueSubject<StreamSettings, Never> = CurrentValueSubject(settings)
    public lazy var settingsPublisher: AnyPublisher<StreamSettings, Never> = settingsSubject.eraseToAnyPublisher()

    private init() {
        if let settings = try? SettingsDictionary.getSettings(for: SettingsDictionary.GlobalStreamId) {
            self.settings = settings
        } else {
            self.settings = .init()
        }
    }

    public func setActiveSetting(for mode: Mode) {
        if self.mode == mode { return }
        self.mode = mode
        if let settings = try? SettingsDictionary.getSettings(for: currentStreamId) {
            self.settings = settings
        } else {
            if let globalSettings = try? SettingsDictionary.getSettings(for: SettingsDictionary.GlobalStreamId) {
                self.settings = globalSettings
            } else {
                self.settings = .init()
            }
            try? SettingsDictionary.saveSettings(for: currentStreamId, settings: self.settings)
        }
    }

    @discardableResult
    public func removeSettings(for streamName: String, with accountID: String) -> Bool {
        let streamId = StreamDetail(streamName: streamName, accountID: accountID).streamId
        if case let .stream(id) = mode {
            guard id != streamId else {
                // Invalid use case
                fatalError("Can't remove an active stream settings")
            }
        }
        do {
            try SettingsDictionary.removeSettings(for: streamId)
        } catch {
            return false
        }
        return true
    }
}

class SettingsDictionary {
    // Fake an ID for global settings
    static let GlobalStreamId = "global/settings"

    private static let UserDefaultKey = "stream-settings"
    typealias Dictionary =  [String: StreamSettings]

    static func getDictionary() throws -> [String: StreamSettings] {
        var dictionary: [String: StreamSettings] = [:]
        let userDefaults = UserDefaults.standard
        let object = userDefaults.object(forKey: SettingsDictionary.UserDefaultKey)
        if let data = object as? Data {
            dictionary = try JSONDecoder().decode(Dictionary.self, from: data)
        }
        return dictionary
    }

    static func getSettings(for streamId: String) throws -> StreamSettings? {
        let dictionary = try getDictionary()
        return dictionary[streamId]
    }

    static func saveDictionary(dictionary: [String: StreamSettings]) throws {
        let data = try JSONEncoder().encode(dictionary)
        UserDefaults.standard.set(data, forKey: SettingsDictionary.UserDefaultKey)
    }

    static func saveSettings(for streamId: String, settings: StreamSettings) throws {
        var dictionary: [String: StreamSettings] = [:]
        if let dict = try? getDictionary() {
            dictionary = dict
        }
        dictionary[streamId] = settings
        try saveDictionary(dictionary: dictionary)
    }

    static func removeSettings(for streamId: String) throws {
        var dictionary = try getDictionary()
        dictionary.removeValue(forKey: streamId)
        try saveDictionary(dictionary: dictionary)
    }

    static func removeDictionary() {
        UserDefaults.standard.removeObject(forKey: SettingsDictionary.UserDefaultKey)
    }
}
