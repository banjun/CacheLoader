import Foundation

public final class Loader<Value>: Sendable {
    private let queue: DispatchQueue
    private nonisolated(unsafe) var _value: Value? = nil // read/write only on the queue
    private let load: @Sendable () async throws -> Value

    private let callerFile: String
    private let callerLine: Int
    private func debugLog(function: String = #function, _ message: String) {
        CacheLoader.debugLog(callerFile: callerFile, callerLine: callerLine, message: message)
    }

    public init(queueLabel: String? = nil, callerFile: String = #file, callerLine: Int = #line, _ load: @escaping @Sendable () async throws -> (Value)) {
        let queueLabel = queueLabel ?? Bundle.module.bundleIdentifier ?? "CacheLoader"
        self.queue = .init(label: queueLabel, qos: .default, attributes: [])
        self.load = load
        self.callerFile = callerFile
        self.callerLine = callerLine
    }

    public var value: Value {
        get async throws {
            debugLog("called")
            return try await withCheckedThrowingContinuation { c in
                queue.async {
                    if let v = self._value {
                        self.debugLog("found already loaded value")
                        c.resume(returning: v)
                    } else {
                        self.debugLog("try loading")
                        let sem = dispatch_semaphore_t(value: 0)
                        Task {
                            do {
                                defer { sem.signal() }
                                let value = try await self.load()
                                self._value = value
                                c.resume(returning: value)
                            } catch {
                                logger.error("\(String(describing: error))")
                                c.resume(throwing: error)
                            }
                        }
                        sem.wait() // block the queue
                        self.debugLog("finished loading")
                    }
                }
            }
        }
    }

    public func unload() async {
        debugLog("called")
        return await withCheckedContinuation { c in
            queue.async {
                self._value = nil
                c.resume()
                self.debugLog("finished unloading")
            }
        }
    }
}
