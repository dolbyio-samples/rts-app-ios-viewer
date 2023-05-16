//
//  StreamError.swift
//

import Foundation

public enum StreamError: Error, Equatable {
    case subscribeFailed(reason: String)
    case connectFailed(reason: String)
    case signalingError(reason: String)
}
