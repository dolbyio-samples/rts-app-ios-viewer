//
//  AVAudioSession++.swift
//  Millicast SDK Sample App in Swift
//

import AVFAudio
import Foundation
import os

extension AVAudioSession {
    private static let logger = Logger(subsystem: Bundle.module.bundleIdentifier!, category: String(describing: AVAudioSession.self))
    public static func configure() {
        let session = Self.sharedInstance()
        do {
#if os(tvOS)
            try session.setCategory(.playback, options: [.mixWithOthers])
#else
            try session.setCategory(.playback, mode: .videoChat, options: [.mixWithOthers, .allowBluetooth])
#endif
            try session.setActive(true)
        } catch {
            Self.logger.debug("📺 Error configuring AVAudioSession \(error.localizedDescription)")
        }
    }
}
