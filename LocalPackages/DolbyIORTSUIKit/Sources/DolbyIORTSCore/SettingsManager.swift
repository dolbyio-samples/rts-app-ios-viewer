//
//  SettingsManager.swift
//

import Combine
import Foundation

open class SettingsManager {

    public enum Mode {
        case global
        case stream(streamID: String)
    }

    public static let shared: SettingsManager = .init()
    public private(set) var mode: Mode = .global
    public private(set) var audioLabels: [String] = []
    public var currentStreamId: String { getStreamId(for: mode) }

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
        self.mode = mode
        if let settings = try? SettingsDictionary.getSettings(for: currentStreamId) {
            self.settings = settings
        } else {
            self.settings = .init()
            try? SettingsDictionary.saveSettings(for: currentStreamId, settings: self.settings)
        }
    }

    public func setAudioLabels(_ labels: [String]) {
        audioLabels = labels
        if case .stream = mode {
            if let label = labels.first {
                settings.audioSelection = .source(label: label)
            }
        }
    }

    private func getStreamId(for mode: Mode) -> String {
        switch mode {
        case .global: return SettingsDictionary.GlobalStreamId
        case .stream(let streamId): return streamId
        }
    }
}

class SettingsDictionary {

    static let GlobalStreamId = "global/settings"   // Fake an ID for global settings

    private static let UserDefaultKey = "stream-settings"
    typealias Dictionary =  [String: StreamSettings]

    static func getDictionary() throws -> [String: StreamSettings] {
        var dictionary: [String: StreamSettings] = [:]
        let userDefaults = UserDefaults.standard
        if let data = userDefaults.object(forKey: SettingsDictionary.UserDefaultKey) as? Data {
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
        var dictionary = try getDictionary()
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
