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
            try session.setCategory(.playback, options: [.mixWithOthers])
            try session.setActive(true)
        } catch {
            // No-op
        }
    }
}
