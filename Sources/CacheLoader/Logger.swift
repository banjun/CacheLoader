import Foundation
import OSLog

let logger = Logger(subsystem: Bundle.module.bundleIdentifier!, category: "Loader")

func debugLog(function: String = #function, callerFile: String, callerLine: Int, message: String) {
#if DEBUG
    logger.debug("Loader(\(callerFile):\(callerLine)) \(function): \(message)")
#endif
}
