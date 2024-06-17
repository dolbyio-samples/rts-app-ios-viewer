//
//  UserDefaultsBacked.swift
//

import Combine
import Foundation

@propertyWrapper
struct UserDefaultsBacked<T> {
    let key: String
    let defaultValue: T
    let userDefaults: UserDefaults

    private let publisher: CurrentValueSubject<T, Never>

    init(key: String, defaultValue: T, container: UserDefaults = .standard) {
        self.key = key
        self.defaultValue = defaultValue
        self.userDefaults = container
        self.publisher = .init(defaultValue)

        // Register default value
        userDefaults.register(defaults: [key: defaultValue])

        self.publisher.send(wrappedValue)
    }

    var wrappedValue: T {
        get {
            return userDefaults.object(forKey: key) as? T ?? defaultValue
        }
        set {
            if let optional = newValue as? AnyOptional, optional.isNil {
                userDefaults.removeObject(forKey: key)
            } else {
                userDefaults.set(newValue, forKey: key)
            }
            publisher.send(newValue)
        }
    }

    var projectedValue: AnyPublisher<T, Never> {
        return publisher.eraseToAnyPublisher()
    }
}

@propertyWrapper
struct UserDefaultsCodableBacked<T: Codable> {
    let key: String
    let defaultValue: T
    let userDefaults: UserDefaults

    private let publisher: CurrentValueSubject<T, Never>

    init(key: String, defaultValue: T, container: UserDefaults = .standard) {
        self.key = key
        self.defaultValue = defaultValue
        self.userDefaults = container
        self.publisher = .init(defaultValue)

        // Register default value
        userDefaults.registerCodableDefaults(defaultValue, forKey: key)

        self.publisher.send(wrappedValue)
    }

    var wrappedValue: T {
        get {
            return userDefaults.getCodableValue(dataType: T.self, key: key) ?? defaultValue
        }
        set {
            if let optional = newValue as? AnyOptional, optional.isNil {
                userDefaults.removeObject(forKey: key)
            } else {
                userDefaults.setCodableValue(newValue, forKey: key)
            }
            publisher.send(newValue)
        }
    }

    var projectedValue: AnyPublisher<T, Never> {
        return publisher.eraseToAnyPublisher()
    }
}

protocol AnyOptional {
    var isNil: Bool { get }
}

extension Optional: AnyOptional {
    var isNil: Bool { self == nil }
}
