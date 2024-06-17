//
//  SerialTasks.swift
//

import Foundation

actor SerialTasks<Success> {
    private var previousTask: Task<Success, Error>?

    func add(block: @Sendable @escaping () async throws -> Success) async throws -> Success {
        let task = Task { [previousTask] in
            _ = await previousTask?.result
            return try await block()
        }
        previousTask = task
        return try await task.value
    }
}
