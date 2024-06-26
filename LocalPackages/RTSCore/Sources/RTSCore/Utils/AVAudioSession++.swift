//
//  AVAudioSession++.swift
//  Millicast SDK Sample App in Swift
//

import AVFAudio
import Foundation

extension AVAudioSession {
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
            // No-op
        }
    }
}
