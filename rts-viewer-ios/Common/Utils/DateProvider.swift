//
//  DateProvider.swift
//

import Foundation

protocol DateProvider {
    var now: Date { get }
}

struct DefaultDateProvider: DateProvider {
    var now: Date {
        Date()
    }
}
