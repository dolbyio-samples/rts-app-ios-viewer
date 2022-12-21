//
//  UiCreds.swift
//  Millicast SDK Sample App in Swift
//

import Foundation
import MillicastSDK

/**
 Serves as the UI based source of Millicast Credentials.
 Reads from UI values in SettingsView.
 Values will be empty Strings ("") if no values were applied in SettingsView.
 */
class UiCreds: CredentialSource {
    var credsType = SourceType.ui
    var streamNamePub = ""
    var tokenPub = ""
    var apiUrlPub = ""
    var accountId = ""
    var streamNameSub = ""
    var apiUrlSub = ""
    var tokenSub = ""

    /**
     Read Millicast credentials and set into MillicastManager using CredentialSource.
     */
    public func setCreds(using creds: CredentialSource) {
        let logTag = "[Creds][Ui][Set] "
        print(logTag + Utils.getCredStr(creds: creds))

        // Publishing
        streamNamePub = creds.getStreamNamePub()
        tokenPub = creds.getTokenPub()
        apiUrlPub = creds.getApiUrlPub()
        // Subscribing
        accountId = creds.getAccountId()
        streamNameSub = creds.getStreamNameSub()
        apiUrlSub = creds.getApiUrlSub()
        tokenSub = creds.getTokenSub()
    }

    func getAccountId() -> String {
        let logTag = "[Creds][Cur][Account][Id] "
        let value = accountId
        print(logTag + value)
        return value
    }
    
    func setAccountId(value: String) {
        let logTag = "[Creds][Cur][Account][Id][Set] "
        accountId = value
        print(logTag + value)
    }
    
    func getStreamNamePub() -> String {
        let logTag = "[Creds][Cur][Pub][Stream][Name] "
        let value = streamNamePub
        print(logTag + value)
        return value
    }
    
    func setStreamNamePub(value: String) {
        let logTag = "[Creds][Cur][Pub][Stream][Name][Set] "
        streamNamePub = value
        print(logTag + value)
    }
    
    func getStreamNameSub() -> String {
        let logTag = "[Creds][Cur][Sub][Stream][Name] "
        let value = streamNameSub
        print(logTag + value)
        return value
    }
    
    func setStreamNameSub(value: String) {
        let logTag = "[Creds][Cur][Sub][Stream][Name][Set] "
        streamNameSub = value
        print(logTag + value)
    }
    
    func getTokenPub() -> String {
        let logTag = "[Creds][Cur][Pub][Token] "
        let value = tokenPub
        print(logTag + value)
        return value
    }
    
    func setTokenPub(value: String) {
        let logTag = "[Creds][Cur][Pub][Token][Set] "
        tokenPub = value
        print(logTag + value)
    }
    
    func getTokenSub() -> String {
        let logTag = "[Creds][Cur][Sub][Token] "
        let value = tokenSub
        print(logTag + value)
        return value
    }
    
    func setTokenSub(value: String) {
        let logTag = "[Creds][Cur][Sub][Token][Set] "
        tokenSub = value
        print(logTag + value)
    }
    
    func getApiUrlPub() -> String {
        let logTag = "[Creds][Cur][Pub][Api][Url] "
        let value = apiUrlPub
        print(logTag + value)
        return value
    }
    
    func setApiUrlPub(value: String) {
        let logTag = "[Creds][Cur][Pub][Api][Url][Set] "
        apiUrlPub = value
        print(logTag + value)
    }
    
    func getApiUrlSub() -> String {
        let logTag = "[Creds][Cur][Sub][Api][Url] "
        let value = apiUrlSub
        print(logTag + value)
        return value
    }
    
    func setApiUrlSub(value: String) {
        let logTag = "[Creds][Cur][Sub][Api][Url][Set] "
        apiUrlSub = value
        print(logTag + value)
    }
}
