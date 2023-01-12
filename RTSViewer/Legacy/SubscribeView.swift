//
//  PublishView.swift
//  Millicast SDK Sample App in Swift
//

import SwiftUI
import DolbyIOUIKit

/**
 * UI for subscribing.
 */
struct SubscribeView: View {
    @ObservedObject var mcMan: MillicastManager
    @State private var volume = 0.5
    
    var mcSA: MillicastSA = .getInstance()
    
    let timer = Timer.publish(every: 5, on: .main, in: .common).autoconnect()
    
    init(manager mcMan: MillicastManager) {
        self.mcMan = mcMan
    }
    
    var body: some View {
        ZStack {
            
            mcMan.getRendererSub()
            
            VStack {
            }.frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.black)
                .opacity(isStreamActive() ? 0.0 : 0.8)
            
            VStack {
                if !isStreamActive() {
                    Text(
                        text: "Stream is offline",
                        fontAsset: .avenirNextDemiBold(
                            size: FontSize.largeTitle,
                            style: .largeTitle
                        )
                    )
                    Text(
                        text: "Please wait for livestream to begin.",
                        fontAsset: .avenirNextRegular(
                            size: FontSize.title3,
                            style: .title3
                        )
                    ).onAppear{
                        mcSA.startSubscribe()
                    }
                }
            }.onReceive(timer) { time in
                if !isStreamActive() {
                    mcSA.startSubscribe()
                } else {
                    timer.upstream.connect().cancel()
                }
            }
            
            Spacer()
        }.onDisappear {
            timer.upstream.connect().cancel()
            mcSA.stopSubscribe()
        }
    }
    
    /**
     * Set the state 
     */
    func getStates() -> Bool
    {
        var streamActive = false
        
        switch mcMan.subState {
        case .disconnected, .connecting, .connected, .subscribing, .streamInActive:
            streamActive = false
        case .streamActive:
            streamActive = true
        }
        
        return streamActive
    }
    
    func isStreamActive() -> Bool {
        return getStates()
    }
}

struct SubscribeView_Previews: PreviewProvider {
    static var previews: some View {
        SubscribeView(manager: MillicastManager.getInstance())
    }
}