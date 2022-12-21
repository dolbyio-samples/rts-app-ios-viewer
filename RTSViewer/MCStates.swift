//
//  MCStates.swift
//  Millicast SDK Sample App in Swift
//

import Foundation

/**
 * Enums for Millicast related states that help ensure Millicast SDK APIs are called in valid ways.
 */

/**
 * States for video capturing.
 */
enum CaptureState {
    case notCaptured
    case tryCapture
    case isCaptured
}

/**
 * States for publishing.
 */
enum PublisherState {
    case disconnected
    case connecting
    case connected
    case publishing
}

/**
 * States for subscribing.
 */
enum SubscriberState {
    case disconnected
    case connecting
    case connected
    case subscribing
}
