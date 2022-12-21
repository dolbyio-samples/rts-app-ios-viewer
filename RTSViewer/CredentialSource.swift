//
//  CredentialSource.swift
//  Millicast SDK Sample App in Swift
//

import Foundation

/**
 Serve as a source of Millicast credentials.
 */
protocol CredentialSource {
    var credsType: SourceType { get }

    func getAccountId() -> String
    func getStreamNamePub() -> String
    func getTokenPub() -> String
    func getTokenSub() -> String
    func getStreamNameSub() -> String
    func getApiUrlPub() -> String
    func getApiUrlSub() -> String
}

enum SourceType {
    case file
    case saved
    case current
    case ui
}
