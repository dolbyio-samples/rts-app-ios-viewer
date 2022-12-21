//
//  CredsManager.swift
//  Millicast SDK Sample App in Swift
//

import Foundation

/**
 Serves as a device memory based source of Millicast Credentials.
 Reads from UserDefaults, if present.
 Otherwise, reads from Constants file.
 */
class SavedCreds: CredentialSource {
    var credsType = SourceType.saved
    let accountId = "ACCOUNT_ID"
    let streamNamePub = "STREAM_NAME_PUB"
    let streamNameSub = "STREAM_NAME_SUB"
    let tokenPub = "TOKEN_PUB"
    let tokenSub = "TOKEN_SUB"
    let apiUrlPub = "URL_PUB"
    let apiUrlSub = "URL_SUB"
    
    func getAccountId() -> String {
        let logTag = "[Creds][Saved][Account][Id] "
        return Utils.getValue(tag: logTag, key: accountId, defaultValue: Constants.ACCOUNT_ID)
    }
    
    func getStreamNamePub() -> String {
        let logTag = "[Creds][Saved][Pub][Stream][Name] "
        return Utils.getValue(tag: logTag, key: streamNamePub, defaultValue: Constants.STREAM_NAME_PUB)
    }
    
    func getStreamNameSub() -> String {
        let logTag = "[Creds][Saved][Sub][Stream][Name] "
        return Utils.getValue(tag: logTag, key: streamNameSub, defaultValue: Constants.STREAM_NAME_SUB)
    }
    
    func getTokenPub() -> String {
        let logTag = "[Creds][Saved][Pub][Token] "
        return Utils.getValue(tag: logTag, key: tokenPub, defaultValue: Constants.TOKEN_PUB)
    }
    
    func getTokenSub() -> String {
        let logTag = "[Creds][Saved][Sub][Token] "
        return Utils.getValue(tag: logTag, key: tokenSub, defaultValue: Constants.TOKEN_SUB)
    }
    
    func getApiUrlPub() -> String {
        let logTag = "[Creds][Saved][Pub][Api][Url] "
        return Utils.getValue(tag: logTag, key: apiUrlPub, defaultValue: Constants.URL_PUB)
    }
    
    func getApiUrlSub() -> String {
        let logTag = "[Creds][Saved][Sub][Api][Url] "
        return Utils.getValue(tag: logTag, key: apiUrlSub, defaultValue: Constants.URL_SUB)
    }
}
