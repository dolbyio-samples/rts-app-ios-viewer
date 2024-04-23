//
//  UserDefaults+Codable.swift
//

import Foundation

extension UserDefaults {
    func registerCodableDefaults<T: Codable>(_ defaults: T, forKey defaultName: String) {
        let encoded = try? JSONEncoder().encode(defaults)
        register(defaults: [defaultName: (encoded ?? nil) as Any])
    }

    func setCodableValue<T: Codable>(_ data: T?, forKey defaultName: String) {
        let encoded = try? JSONEncoder().encode(data)
        set(encoded, forKey: defaultName)
    }

    func getCodableValue<T: Codable>(dataType: T.Type, key: String) -> T? {
        guard let userDefaultData = data(forKey: key) else {
            return nil
        }
        return try? JSONDecoder().decode(T.self, from: userDefaultData)
    }
}
