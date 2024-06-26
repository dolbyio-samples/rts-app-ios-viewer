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
            try session.setCategory(.playback, mode: .videoChat, options: [.mixWithOthers, .allowBluetooth])
            try session.setActive(true)
        } catch {
            // No-op
        }
    }
}
