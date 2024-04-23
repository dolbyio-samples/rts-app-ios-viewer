//
//  Utils.swift
//

import AVFAudio
import Foundation

/**
 * Utility methods used in the SA.
 */
class Utils {
    public static func configureAudioSession() {
        let session = AVAudioSession.sharedInstance()
        do {
#if os(iOS)
            // For subscriber, we only need playback. Not recording is required.
            try session.setCategory(.playback, mode: .videoChat, options: [.mixWithOthers, .allowBluetooth])
#else
            try session.setCategory(.playback, options: [.mixWithOthers, .allowBluetooth])
#endif
            try session.setActive(true)
        } catch {
            print("Failed audio session: \(error)")
            return
        }
    }
}
