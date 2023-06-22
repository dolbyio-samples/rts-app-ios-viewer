//
//  MockDateProvider.swift
//

@testable import RTSViewer_TVOS
import Foundation

final class MockDateProvider: DateProvider {

    var dateToReturn: Date

    init(date: Date) {
        self.dateToReturn = date
    }

    var now: Date {
        dateToReturn
    }
}
