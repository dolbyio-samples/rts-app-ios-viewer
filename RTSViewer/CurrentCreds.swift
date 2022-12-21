//
//  CurrentCreds.swift
//  Millicast SDK Sample App in Swift
//

import Foundation
import MillicastSDK

/**
 Serves as the currently applied source of Millicast Credentials.
 Reads from currently applied values in MillicastManager.
 Values will be empty Strings ("") if no values were applied in MillicastManager.
 */
class CurrentCreds: CredentialSource {
    var credsType = SourceType.current
    
    var mcMan: MillicastManager
    var pubCreds: MCPublisherCredentials {
        return mcMan.credsPub
    }

    var subCreds: MCSubscriberCredentials {
        return mcMan.credsSub
    }
    
    init(mcMan: MillicastManager) {
        self.mcMan = mcMan
    }
    
    func getAccountId() -> String {
        let logTag = "[Creds][Cur][Account][Id] "
        let value = subCreds.accountId ?? ""
        print(logTag + value)
        return value
    }
    
    func getStreamNamePub() -> String {
        let logTag = "[Creds][Cur][Pub][Stream][Name] "
        let value = pubCreds.streamName ?? ""
        print(logTag + value)
        return value
    }
    
    func getStreamNameSub() -> String {
        let logTag = "[Creds][Cur][Sub][Stream][Name] "
        let value = subCreds.streamName ?? ""
        print(logTag + value)
        return value
    }
    
    func getTokenPub() -> String {
        let logTag = "[Creds][Cur][Pub][Token] "
        let value = pubCreds.token ?? ""
        print(logTag + value)
        return value
    }
    
    func getTokenSub() -> String {
        let logTag = "[Creds][Cur][Sub][Token] "
        let value = subCreds.token ?? ""
        print(logTag + value)
        return value
    }
    
    func getApiUrlPub() -> String {
        let logTag = "[Creds][Cur][Pub][Api][Url] "
        let value = pubCreds.apiUrl ?? ""
        print(logTag + value)
        return value
    }
    
    func getApiUrlSub() -> String {
        let logTag = "[Creds][Cur][Sub][Api][Url] "
        let value = subCreds.apiUrl ?? ""
        print(logTag + value)
        return value
    }
}
