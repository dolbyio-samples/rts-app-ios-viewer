//
//  AppConfigurations.swift
//

import Combine
import Foundation
import SwiftUI

public final class AppConfigurations {

    public static let standard = AppConfigurations(userDefaults: .standard)
    fileprivate let userDefaults: UserDefaults

    fileprivate let _appConfigurationsChangedSubject = PassthroughSubject<AnyKeyPath, Never>()
    fileprivate lazy var appConfigurationsChangedSubject = {
        _appConfigurationsChangedSubject.eraseToAnyPublisher()
    }()

    init(userDefaults: UserDefaults) {
        self.userDefaults = userDefaults
    }

    @UserDefault("show_debug_features")
    public var showDebugFeatures: Bool = false

    @UserDefault("enable_pip")
    public var enablePiP: Bool = false
}

@propertyWrapper
public struct UserDefault<Value> {
    let key: String
    let defaultValue: Value

    public var wrappedValue: Value {
        get { fatalError("Wrapped value should not be used.") }
        set { fatalError("Wrapped value should not be used.") }
    }

    init(wrappedValue: Value, _ key: String) {
        self.defaultValue = wrappedValue
        self.key = key
    }

    public static subscript(
        _enclosingInstance instance: AppConfigurations,
        wrapped wrappedKeyPath: ReferenceWritableKeyPath<AppConfigurations, Value>,
        storage storageKeyPath: ReferenceWritableKeyPath<AppConfigurations, Self>
    ) -> Value {
        get {
            let container = instance.userDefaults
            let key = instance[keyPath: storageKeyPath].key
            let defaultValue = instance[keyPath: storageKeyPath].defaultValue
            return container.object(forKey: key) as? Value ?? defaultValue
        }
        set {
            let container = instance.userDefaults
            let key = instance[keyPath: storageKeyPath].key
            container.set(newValue, forKey: key)
            instance._appConfigurationsChangedSubject.send(wrappedKeyPath)
        }
    }
}

@propertyWrapper
public struct AppConfiguration<Value>: DynamicProperty {

    @ObservedObject private var appConfigurationsObserver: PublisherObservableObject
    private let keyPath: ReferenceWritableKeyPath<AppConfigurations, Value>
    private let appConfigurations: AppConfigurations

    public init(_ keyPath: ReferenceWritableKeyPath<AppConfigurations, Value>, appConfigurations: AppConfigurations = .standard) {
        self.keyPath = keyPath
        self.appConfigurations = appConfigurations
        let publisher = appConfigurations
            .appConfigurationsChangedSubject
            .filter { changedKeyPath in
                changedKeyPath == keyPath
            }.map { _ in () }
            .eraseToAnyPublisher()
        self.appConfigurationsObserver = .init(publisher: publisher)
    }

    public var wrappedValue: Value {
        get { appConfigurations[keyPath: keyPath] }
        nonmutating set { appConfigurations[keyPath: keyPath] = newValue }
    }

    public var projectedValue: Binding<Value> {
        Binding(
            get: { wrappedValue },
            set: { wrappedValue = $0 }
        )
    }
}

final class PublisherObservableObject: ObservableObject {

    var subscriber: AnyCancellable?

    init(publisher: AnyPublisher<Void, Never>) {
        subscriber = publisher.sink(receiveValue: { [weak self] _ in
            self?.objectWillChange.send()
        })
    }
}
