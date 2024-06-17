//
//  SerialTasks.swift
//

import Foundation

actor SerialTasks {
    private var isRunning: Bool = false
    private var queue = [CheckedContinuation<Void, Error>]()

    deinit {
        for continuation in queue {
            continuation.resume(throwing: CancellationError())
        }
    }

    public func enqueue<T>(operation: @escaping @Sendable () async throws -> T) async throws -> T {
        try Task.checkCancellation()

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            queue.append(continuation)
            tryRunEnqueued()
        }

        defer {
            isRunning = false
            tryRunEnqueued()
        }
        try Task.checkCancellation()
        return try await operation()
    }

    private func tryRunEnqueued() {
        guard !queue.isEmpty, !isRunning else { return }

        isRunning = true
        let continuation = queue.removeFirst()
        continuation.resume()
    }
}
