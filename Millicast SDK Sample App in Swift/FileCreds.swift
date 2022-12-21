//
//  FileCreds.swift
//  Millicast SDK Sample App in Swift
//

import Foundation

/**
 Serves as a file based source of Millicast Credentials.
 Reads from Constants.swift.
 */
class FileCreds: CredentialSource {
    var credsType = SourceType.file
    func getAccountId() -> String {
        let logTag = "[Creds][File][Account][Id] "
        let value = Constants.ACCOUNT_ID
        print(logTag + value)
        return value
    }
    
    func getStreamNamePub() -> String {
        let logTag = "[Creds][File][Pub][Stream][Name] "
        let value = Constants.STREAM_NAME_PUB
        print(logTag + value)
        return value
    }
    
    func getStreamNameSub() -> String {
        let logTag = "[Creds][File][Sub][Stream][Name] "
        let value = Constants.STREAM_NAME_SUB
        print(logTag + value)
        return value
    }
    
    func getTokenPub() -> String {
        let logTag = "[Creds][File][Pub][Token] "
        let value = Constants.TOKEN_PUB
        print(logTag + value)
        return value
    }
    
    func getTokenSub() -> String {
        let logTag = "[Creds][File][Sub][Token] "
        let value = Constants.TOKEN_SUB
        print(logTag + value)
        return value
    }
    
    func getApiUrlPub() -> String {
        let logTag = "[Creds][File][Pub][Api][Url] "
        let value = Constants.URL_PUB
        print(logTag + value)
        return value
    }
    
    func getApiUrlSub() -> String {
        let logTag = "[Creds][File][Sub][Api][Url] "
        let value = Constants.URL_SUB
        print(logTag + value)
        return value
    }
}
