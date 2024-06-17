//
//  String+Error.swift
//

import Foundation

extension String {
    static let offlineErrorTitle = String(localized: "stream-offline.title.label", bundle: .module)
    static let offlineErrorSubtitle = String(localized: "stream-offline.subtitle.label", bundle: .module)

    static let noInternetErrorTitle = String(localized: "network.disconnected.title.label", bundle: .module)

    static let genericErrorTitle = String(localized: "technical-error.title.label", bundle: .module)
}
