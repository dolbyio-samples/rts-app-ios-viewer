//
//  StreamType.swift
//

import Foundation

public enum StreamType: String, CaseIterable, Identifiable {
    case auto, high, medium, low
    public var id: Self { self }
}
