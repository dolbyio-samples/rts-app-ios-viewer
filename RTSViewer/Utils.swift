//
//  Utils.swift
//  Millicast SDK Sample App in Swift
//

import AVFAudio
import Foundation

/**
 * Utility methods used in the SA.
 */
class Utils {
    /**
     * Gets a String representing the specified CredentialSource.
     */
    public static func getCredStr(creds: CredentialSource) -> String {
        let str = "Account ID: \(creds.getAccountId())\n\t" +
            "Publishing stream name: \(creds.getStreamNamePub())\n\t" +
            "Subscribing stream name: \(creds.getStreamNameSub())\n\t" +
            "Publishing token: \(creds.getTokenPub())\n\t" +
            "Subscribing token: \(creds.getTokenSub())\n\t" +
            "Publishing API url: \(creds.getApiUrlPub())\n\t" +
            "Subscribing API url: \(creds.getApiUrlSub())\n\t"
        return str
    }

    /**
     * Configures the AVAudioSession to use:
     * - Category playAndRecord for iOS, or playback for tvOS, with the mixWithOthers option.
     *  - This will allow:
     *   - Recording on iOS.
     *   - Audio playback in the backgroud, and even when the screen is locked.
     *   - Mixing with audio from other apps that also allow mixing.
     * - Mode videoChat, which will optimise the audio for voice and allow Bluetooth Hands-Free Profile (HFP) device as input and output.
     * - Audio will default to the device's speakers when no other audio route is connected.
     * For full control of the AVAudioSession, this method should be called:
     * - When the Subscriber's audioTrack is rendered, for e.g. at MillicastManager.subRenderAudio(track: MCAudioTrack?).
     * - When the AVAudioSession route changes, for e.g. at MillicastSA.routeChangeHandler(notification: Notification).
     */
    public static func configureAudioSession() {
        let logTag = "[Configure][Audio][Session] "
        let session = AVAudioSession.sharedInstance()
        print(logTag + "Now: " + Utils.audioSessionStr(session: session))
        do {
            #if os(iOS)
            try session.setCategory(AVAudioSession.Category.playAndRecord, mode: .videoChat, options: [.mixWithOthers])
            #else
            try session.setCategory(AVAudioSession.Category.playback, options: [.mixWithOthers])
            #endif
            try session.setActive(true)
        } catch {
            print(logTag + "Failed! Error: \(error)")
            return
        }
        print(logTag + "OK. " + Utils.audioSessionStr(session: session))
    }

    /**
     * Sets the AVAudioSession to active or not active as indicated by the parameter.
     */
    public static func setAudioSession(active: Bool) {
        #if os(iOS)
        let logTag = "[Configure][Audio][Session][Active] "
        let session = AVAudioSession.sharedInstance()
        do {
            if active {
                try session.setActive(true)
            } else {
                try session.setActive(false, options: AVAudioSession.SetActiveOptions.notifyOthersOnDeactivation)
            }
        } catch {
            print(logTag + "Failed! Error: \(error)")
            return
        }
        print(logTag + "OK. SetActive \(active).")
        #endif
    }

    /**
     * Gets a String representing characteristics of the current AVAudioSession.
     */
    public static func audioSessionStr(session: AVAudioSession) -> String {
        let cat = String(describing: session.category.rawValue)
        let catOpts = audioCatOptStr(value: session.categoryOptions.rawValue)
        let mode = String(describing: session.mode.rawValue)
        let gain = session.inputGain
        let vol = session.outputVolume
        let channelNumIn = session.inputNumberOfChannels
        let channelNumOut = session.outputNumberOfChannels
        let portsIn = inputAudioStr(route: session.currentRoute)
        let portsOut = outputAudioStr(route: session.currentRoute)
        var oriIn = "-"
        #if os(iOS)
        oriIn = String(describing: session.inputOrientation.rawValue)
        #endif

        let str = "AVAudioSession: Category:\(cat) options:\(catOpts) Mode:\(mode) Gain:\(gain) Vol:\(vol) Channels in:\(channelNumIn) out:\(channelNumOut) Ports in:\(portsIn) out:\(portsOut) orientation:\(oriIn)."
        return str
    }

    /**
     * Gets a String representing the specified AVAudioSession.CategoryOptions.
     */
    public static func audioCatOptStr(value: UInt) -> String {
        var opt = AVAudioSession.CategoryOptions(rawValue: value)
        var str = ""

        addOptToStr(catOpt: .mixWithOthers, desc: "mixWithOthers")
        addOptToStr(catOpt: .duckOthers, desc: "duckOthers")
        #if os(iOS)
        addOptToStr(catOpt: .allowBluetooth, desc: "allowBluetooth")
        addOptToStr(catOpt: .defaultToSpeaker, desc: "defaultToSpeaker")
        #endif
        addOptToStr(catOpt: .interruptSpokenAudioAndMixWithOthers, desc: "interruptSpokenAudioAndMixWithOthers")
        addOptToStr(catOpt: .allowBluetoothA2DP, desc: "allowBluetoothA2DP")
        addOptToStr(catOpt: .allowAirPlay, desc: "allowAirPlay")
        #if os(iOS)
        addOptToStr(catOpt: .overrideMutedMicrophoneInterruption, desc: "overrideMutedMicrophoneInterruption")
        #endif

        if str.isEmpty {
            str = "-"
        } else {
            str = String(str.dropFirst(1))
        }
        str = "[\(str)]"

        func addOptToStr(catOpt: AVAudioSession.CategoryOptions, desc: String) {
            if !opt.contains(catOpt) {
                return
            }
            str += "," + desc
        }

        return str
    }

    /**
     Logs the current and previous audio output device.
     */
    public static func audioOutputLog(userInfo: [AnyHashable: Any]) -> String {
        var log = ""
        // Get current
        let session = AVAudioSession.sharedInstance()
        let routeCur = session.currentRoute
        let routeCurStr = outputAudioStr(route: routeCur)
        log += "Cur: \(routeCurStr), Old: "

        // Get previous
        guard let routePrev =
            userInfo[AVAudioSessionRouteChangePreviousRouteKey] as? AVAudioSessionRouteDescription
        else {
            log += "None!"
            return log
        }

        let routePrevStr = outputAudioStr(route: routePrev)
        log += "\(routePrevStr)"

        return log
    }

    /**
     * Gets a String representation of the audio input port(s) in the given AVAudioSessionRouteDescription.
     */
    public static func inputAudioStr(route routeDescription: AVAudioSessionRouteDescription) -> String {
        var ports = portStr(ports: routeDescription.inputs)
        return ports
    }

    /**
     * Gets a String representation of the audio output port(s) in the given AVAudioSessionRouteDescription.
     */
    public static func outputAudioStr(route routeDescription: AVAudioSessionRouteDescription) -> String {
        var ports = portStr(ports: routeDescription.outputs)
        return ports
    }

    /**
     * Gets a String representation of the given list of AVAudioSessionPortDescription.
     */
    public static func portStr(ports: [AVAudioSessionPortDescription]) -> String {
        var portStr = ""
        for port in ports {
            portStr += "\(port.portType.rawValue),"
        }
        if portStr != "" {
            portStr.removeLast()
        }
        return portStr
    }

    /**
     * Gets a String value from UserDefaults, if available.
     * If not, return the specified defaultValue.
     */
    public static func getValue(tag: String, key: String, defaultValue: String) -> String {
        var value: String
        var log = ""

        if let savedValue = UserDefaults.standard.string(forKey: key) {
            log = "Used saved UserDefaults."
            value = savedValue
        } else {
            value = defaultValue
            log = "No UserDefaults, used default value."
        }
        log = "\(tag) \(value) - \(log)"
        print(log)
        return value
    }

    /**
     * Gets an integer value from UserDefaults, if available.
     * If not, return the specified defaultValue.
     */
    public static func getValue(tag: String, key: String, defaultValue: Int) -> Int {
        var value: Int
        var log = ""

        if let savedValue = UserDefaults.standard.object(forKey: key) {
            log = "Used saved UserDefaults."
            value = savedValue as! Int
        } else {
            value = defaultValue
            log = "No UserDefaults, used default value."
        }
        log = "\(tag) \(value) - \(log)"
        print(log)
        return value
    }

    /**
     * Given a list of specified size and the current index, gets the next index.
     * If at end of list, cycle to start of the other end.
     * Returns null if none available.
     *
     * @param size      Size of the list.
     * @param now       Current index of the list.
     * @param ascending If true, cycle in the direction of increasing index,
     *                  otherwise cycle in opposite direction.
     * @param logTag
     * @return
     */
    public static func indexNext(size: Int, now: Int, ascending: Bool, logTag: String) -> Int {
        var next: Int
        if ascending {
            if now >= (size - 1) {
                next = 0
                print(logTag + "\(next) (Cycling back to start)")
            } else {
                next = now + 1
                print(logTag + "\(next) Incrementing index.")
            }
        } else {
            if now <= 0 {
                next = size - 1
                print(logTag + "\(next) (Cycling back to end)")
            } else {
                next = now - 1
                print(logTag + "\(next) Decrementing index.")
            }
        }
        print(logTag + "Next: " + "\(next) Now: \(now)")
        return next
    }
}
