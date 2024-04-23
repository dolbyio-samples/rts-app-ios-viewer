//
//  TaskScheduler.swift
//

import Combine
import Foundation
import os

protocol TaskSchedulerProtocol: AnyObject {
    func scheduleTask(timeInterval: TimeInterval, task: @escaping () -> Void)
    func invalidate()
}

final class TaskScheduler: TaskSchedulerProtocol {
    private static let logger = Logger.make(category: String(describing: TaskScheduler.self))

    private var subscriptions: Set<AnyCancellable> = []

    func scheduleTask(timeInterval: TimeInterval, task: @escaping () -> Void) {
        Self.logger.debug("⏰ Scheduled task at \(Date()) to execute after time interval \(timeInterval)")

        subscriptions.removeAll()
        let timer = Timer.publish(every: timeInterval, on: .main, in: .common)

        timer.autoconnect().sink { _ in
            Self.logger.debug("⏰ Executed task at \(Date())")
            task()
        }.store(in: &subscriptions)
    }

    func invalidate() {
        Self.logger.debug("⏰ Invalidate timer")
        subscriptions.removeAll()
    }
}
