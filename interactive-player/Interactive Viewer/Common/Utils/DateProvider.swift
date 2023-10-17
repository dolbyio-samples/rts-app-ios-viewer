//
//  DateProvider.swift
//

import Foundation

protocol DateProvider {
    var now: Date { get }
}

struct DefaultDateProvider: DateProvider {

    init() { }

    var now: Date {
        Date()
    }
}
