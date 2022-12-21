//
//  PublishView.swift
//  Millicast SDK Sample App in Swift
//

import AVKit
import SwiftUI

/**
 * UI for publishing.
 */
struct PublishView: View {
    @ObservedObject var mcMan: MillicastManager
    
    static let labelCaptureStart = "Start Capture"
    static let labelCaptureTry = "Trying to Capture..."
    static let labelCaptureStop = "Stop Capture"
    static let labelPublishNot = "Not Publishing"
    static let labelPublishStart = "Start Publish"
    static let labelPublishTry = "Trying to Publish..."
    static let labelPublishStop = "Stop Publish"
    static let labelAudioNo = "No Audio"
    static let labelAudioMute = "Mute Audio"
    static let labelAudioUnmute = "Unmute Audio"
    static let labelVideoNo = "No Video"
    static let labelVideoMute = "Mute Video"
    static let labelVideoUnmute = "Unmute Video"
    
    var mcSA: MillicastSA = .getInstance()
    
    init(manager mcMan: MillicastManager) {
        self.mcMan = mcMan
        print("[PubView][init]")
    }
    
    var body: some View {
        VStack {
            mcMan.getRendererPub()
            VStack {
                Text("Stream: \(mcMan.credsPub.streamName)")
                Text("Token:\(mcMan.credsPub.token)")
                    .multilineTextAlignment(.center)
            }
            Spacer()
            HStack {
                Button(getLabelCamera()) {
                    mcSA.toggleCamera()
                    print("[PubView] Toggled Camera.")
                }.padding().disabled(mcMan.capState != CaptureState.notCaptured)
                
                Button(getLabelResolution()) {
                    mcSA.toggleResolution()
                    print("[PubView] Toggled resolution.")
                }.padding().disabled(mcMan.capState != CaptureState.notCaptured)
                
                Button(getLabelCapture()) {
                    print("[PubView] Capture.")
                    getActionCapture()()
                }.padding().disabled(!getEnableCapture())
            }
            Spacer()
            HStack {
                Button("Switch Camera") {
                    print("[PubView] Switch Camera")
                    mcSA.switchCamera()
                }.padding().disabled(!getEnableSwitch())
                
                Button(getLabelMirror()) {
                    print("[PubView] Switched Mirror.")
                    mcMan.switchMirror()
                }.padding().disabled(!getEnableVideo())
                
                Button(getLabelAudio()) {
                    print("[PubView] Toggled Audio.")
                    mcSA.toggleMedia(forPublisher: true, forAudio: true)
                }.padding().disabled(!getEnableAudio())
                
                Button(getLabelVideo()) {
                    print("[PubView] Toggled Video.")
                    mcSA.toggleMedia(forPublisher: true, forAudio: false)
                }.padding().disabled(!getEnableVideo())
                
                Button(getLabelPublish()) {
                    print("[PubView] Publish.")
                    getActionPublish()()
                }.padding().disabled(!getEnablePublish())
            }
            Spacer()
        }.alert(isPresented: $mcMan.alert) {
            Alert(title: Text("Alert"), message: Text(mcMan.alertMsg), dismissButton: .default(Text("OK")))
        }
    }
    
    /**
     * Set the states of capture, publish, audio and video buttons,
     * based on current capture, publish and media states.
     * Capture state:
     * - Cannot change when publishing.
     * Publish state:
     * - Must first capture and connect before publish.
     */
    func getStates() -> (labelCapture: String,
                         actionCapture: () -> (),
                         enableCapture: Bool,
                         enableSwitch: Bool,
                         labelPublish: String,
                         actionPublish: () -> (),
                         enablePublish: Bool,
                         enableAudio: Bool,
                         enableVideo: Bool)
    {
        var labelCapture = ""
        var actionCapture: (() -> ()) = {}
        var enableCapture = false
        var enableSwitch = false
        var labelPublish = ""
        var actionPublish: (() -> ()) = {}
        var enablePublish = false
        // Whether to enable buttons for Audio/Video on the UI.
        var enableAudio = false
        var enableVideo = false
        
        var readyToPublish = false
        var canChangeCapture = false
        if mcMan.capState == .isCaptured {
            readyToPublish = true
        }
        if mcMan.pubState == .disconnected {
            canChangeCapture = true
        }
        
        if canChangeCapture {
            switch mcMan.capState {
            case .notCaptured:
                labelCapture = PublishView.labelCaptureStart
                actionCapture = mcSA.startCapture
                enableCapture = true
            case .tryCapture:
                labelCapture = PublishView.labelCaptureTry
                enableCapture = false
            case .isCaptured:
                labelCapture = PublishView.labelCaptureStop
                actionCapture = mcSA.stopCapture
                enableCapture = true
                enableSwitch = true
                // If not publishing, only allow audio/video buttons to be enabled when video is captured.
                enableAudio = true
                enableVideo = true
            }
        } else {
            enableCapture = false
            enableSwitch = true
        }
        
        if !readyToPublish {
            if mcMan.pubState == .disconnected {
                labelPublish = PublishView.labelPublishNot
                enablePublish = false
                return (labelCapture, actionCapture, enableCapture, enableSwitch, labelPublish, actionPublish, enablePublish, enableAudio, enableVideo)
            }
        }
        
        switch mcMan.pubState {
        case .disconnected:
            labelPublish = PublishView.labelPublishStart
            actionPublish = mcSA.startPublish
            enablePublish = true
        case .connecting, .connected:
            labelPublish = PublishView.labelPublishTry
            enablePublish = false
        case .publishing:
            labelPublish = PublishView.labelPublishStop
            actionPublish = mcSA.stopPublishCapture
            enablePublish = true
        }
        // Always allow audio/video buttons to be enabled when able to publish, as publisher might want to start publish with audio/video muted.
        enableAudio = true
        enableVideo = true
        
        return (labelCapture, actionCapture, enableCapture, enableSwitch, labelPublish, actionPublish, enablePublish, enableAudio, enableVideo)
    }
    
    func getLabelCamera() -> String {
        return "\(mcSA.getCameraName())"
    }
    
    func getLabelResolution() -> String {
        return "\(mcSA.getResolution())"
    }
    
    func getLabelCapture() -> String {
        return getStates().labelCapture
    }
    
    func getActionCapture() -> (() -> ()) {
        return getStates().actionCapture
    }
    
    func getEnableCapture() -> Bool {
        return getStates().enableCapture
    }
    
    func getEnableSwitch() -> Bool {
        return getStates().enableSwitch
    }
    
    func getLabelPublish() -> String {
        return getStates().labelPublish
    }
    
    func getActionPublish() -> (() -> ()) {
        return getStates().actionPublish
    }
    
    func getEnablePublish() -> Bool {
        return getStates().enablePublish
    }
    
    func getLabelAudio() -> String {
        if getEnableAudio() {
            if mcMan.audioEnabledPub {
                return PublishView.labelAudioMute
            } else {
                return PublishView.labelAudioUnmute
            }
        }
        return PublishView.labelAudioNo
    }
    
    func getEnableAudio() -> Bool {
        return getStates().enableAudio
    }
    
    func getLabelVideo() -> String {
        if getEnableVideo() {
            if mcMan.videoEnabledPub {
                return PublishView.labelVideoMute
            } else {
                return PublishView.labelVideoUnmute
            }
        }
        return PublishView.labelVideoNo
    }
    
    func getEnableVideo() -> Bool {
        return getStates().enableVideo
    }
    
    /**
     * Shows the Mirrored state (true / false) of the Publisher's local view.
     * When video is not captured, that state is indicated.
     */
    func getLabelMirror() -> String {
        var mirror = "Mirror: "
        if getEnableVideo() {
            if mcMan.mirroredPub {
                mirror += "T"
            } else {
                mirror += "F"
            }
            return mirror
        }
        return mirror + PublishView.labelVideoNo
    }
}

struct PublishView_Previews: PreviewProvider {
    static var previews: some View {
        PublishView(manager: MillicastManager.getInstance())
    }
}
