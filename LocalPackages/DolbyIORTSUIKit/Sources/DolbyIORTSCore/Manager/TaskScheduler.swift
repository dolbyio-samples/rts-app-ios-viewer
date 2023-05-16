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

    private var subscriptions: Set<AnyCancellable> = []

    func scheduleTask(timeInterval: TimeInterval, task: @escaping () -> Void) {
        subscriptions.removeAll()
        let timer = Timer.publish(every: timeInterval, on: .main, in: .common)

        timer.autoconnect().sink { _ in
            task()
        }.store(in: &subscriptions)
    }

    func invalidate() {
        subscriptions.removeAll()
    }
}
