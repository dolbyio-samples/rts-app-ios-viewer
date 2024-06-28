//
//  LocalizedStringKey++.swift
//

import SwiftUI

extension LocalizedStringKey {

    var stringKey: String? {
        Mirror(reflecting: self).children.first(where: { $0.label == "key" })?.value as? String
    }

    /**
     Return localized value of thisLocalizedStringKey
     */
    public func toString(with bundle: Bundle = .main) -> String {
        // Use reflection
        let mirror = Mirror(reflecting: self)

        // Try to find 'key' attribute value
        let attributeLabelAndValue = mirror.children.first { (arg0) -> Bool in
            let (label, _) = arg0
            if label == "key" {
                return true
            }
            return false
        }

        if attributeLabelAndValue != nil {
            // Ask for localization of found key via NSLocalizedString
            // swiftlint:disable force_cast
            return String.localizedStringWithFormat(NSLocalizedString(attributeLabelAndValue!.value as! String, bundle: bundle, comment: ""))
            // swiftlint:enable force_cast
        } else {
            return ""
        }
    }
}
