//
//  PublishView.swift
//  Millicast SDK Sample App in Swift
//

import AVFoundation
import SwiftUI

/**
 * UI for Millicast platform settings.
 */
struct SettingsMcView: View, CredentialSource {
    @State var accountId = ""
    @State var streamNamePub = ""
    @State var streamNameSub = ""
    @State var tokenPub = ""
    @State var tokenSub = ""
    @State var apiUrlPub = ""
    @State var apiUrlSub = ""
    
    /**
     Creds TextField background color to use if UI value has been applied.
     */
    private let colorApplied = Color.yellow.opacity(0.2)
    /**
     Creds TextField background color to use if UI value differs from that applied.
     */
    private let colorChanged = Color.black.opacity(0.2)
    
    @ObservedObject var mcMan: MillicastManager
    @ObservedObject var mcSA: MillicastSA
    var credsType = SourceType.ui
    
    init(manager mcMan: MillicastManager) {
        self.mcMan = mcMan
        mcSA = MillicastSA.getInstance()
    }
    
    var body: some View {
        VStack {
            HStack {
                Text("Account ID:")
                TextField("Account ID", text: $accountId).background(useColor(ui: accountId, applied: mcSA.accountId))
            }
#if os(iOS)
            HStack {
                Text("Publishing stream name:")
                TextField("Publishing stream name", text: $streamNamePub).background(useColor(ui: streamNamePub, applied: mcSA.streamNamePub))
            }
#endif
            HStack {
                Text("Subscribing stream name:")
                TextField("Subscribing stream name", text: $streamNameSub).background(useColor(ui: streamNameSub, applied: mcSA.streamNameSub))
            }
#if os(iOS)
            HStack {
                Text("Publishing token:")
                TextField("Publishing token", text: $tokenPub).background(useColor(ui: tokenPub, applied: mcSA.tokenPub))
            }
#endif
            HStack {
                Text("Subscribing token:")
                TextField("Subscribing token", text: $tokenSub).background(useColor(ui: tokenSub, applied: mcSA.tokenSub))
            }
#if os(iOS)
            HStack {
                Text("Publishing API url:")
                TextField("Publishing API url", text: $apiUrlPub).background(useColor(ui: apiUrlPub, applied: mcSA.apiUrlPub))
            }
#endif
            HStack {
                Text("Subscribing API url:")
                TextField("Subscribing API url", text: $apiUrlSub).background(useColor(ui: apiUrlSub, applied: mcSA.apiUrlSub))
            }
            HStack {
                VStack {
                    Spacer()
                    Text("Load values using:").padding()
                    
                    Button("APPLIED") {
                        setUiCreds(creds: mcSA.getCurrentCreds())
                    }
                    Spacer()
                    Button("MEMORY") {
                        setUiCreds(creds: mcSA.getSavedCreds())
                    }
                    Spacer()
                    Button("FILE") {
                        setUiCreds(creds: mcSA.getFileCreds())
                    }
                    Spacer()
                }
                VStack {
                    Spacer()
                    Text("Changes only apply after clicking:").padding()
                    Button("Apply UI values") {
                        mcSA.setCreds(from: self, save: false)
                    }
                    Spacer()
                    Button("Apply & save UI values") {
                        mcSA.setCreds(from: self, save: true)
                    }
                    Spacer()
                }
            }
            Spacer()
        }.padding()
            .alert(isPresented: $mcMan.alert) {
                Alert(title: Text("Alert"), message: Text(mcMan.alertMsg), dismissButton: .default(Text("OK")))
            }.onAppear {
                setUiCreds(creds: mcSA.getUiCreds())
                let logTag = "[SetView][Appear] "
                print(logTag + Utils.getCredStr(creds: self))
            }.onDisappear {
                mcSA.setUiCreds(self)
            }
    }
    
    /**
     Load the UI credentials values using the specified CredentialSource.
     */
    private func setUiCreds(creds: CredentialSource) {
        let logTag = "[Creds][Ui][Set] "
        let log = "Setting Creds of type \(creds.credsType) to UI."
        print(logTag + log)
        
        accountId = creds.getAccountId()
        streamNamePub = creds.getStreamNamePub()
        streamNameSub = creds.getStreamNameSub()
        tokenPub = creds.getTokenPub()
        tokenSub = creds.getTokenSub()
        apiUrlPub = creds.getApiUrlPub()
        apiUrlSub = creds.getApiUrlSub()
    }

    /**
     Return the background color for a creds entry.
     If the current UI value of the creds has been applied, colorApplied will be returned.
     If the current UI value of the creds differs from the creds applied, colorChanged will be returned.
     */
    private func useColor(ui: String, applied: String) -> Color {
        if ui == applied {
            return colorApplied
        } else {
            return colorChanged
        }
    }
    
    public func getAccountId() -> String {
        return accountId
    }

    public func getStreamNamePub() -> String {
        return streamNamePub
    }
    
    public func getTokenPub() -> String {
        return tokenPub
    }
    
    public func getTokenSub() -> String {
        return tokenSub
    }
    
    public func getStreamNameSub() -> String {
        return streamNameSub
    }
    
    public func getApiUrlPub() -> String {
        return apiUrlPub
    }
    
    public func getApiUrlSub() -> String {
        return apiUrlSub
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsMcView(manager: MillicastManager.getInstance())
    }
}
