import Foundation
import OSLog

/// A simple debug logger to help track what's happening in the app
enum DebugLogger {
    static let isDebugMode = true
    static let logger = Logger(subsystem: "com.ychekin.ClosetCurator", category: "Debug")
    
    static func log(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        if isDebugMode {
            let fileName = (file as NSString).lastPathComponent
            let logMessage = "[\(fileName):\(line)] \(function) - \(message)"
            logger.debug("\(logMessage)")
            print("DEBUG: \(logMessage)")
        }
    }
    
    static func error(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        let fileName = (file as NSString).lastPathComponent
        let logMessage = "[\(fileName):\(line)] \(function) - ERROR: \(message)"
        logger.error("\(logMessage)")
        print("ERROR: \(logMessage)")
    }
    
    static func info(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        if isDebugMode {
            let fileName = (file as NSString).lastPathComponent
            let logMessage = "[\(fileName):\(line)] \(function) - \(message)"
            logger.info("\(logMessage)")
            print("INFO: \(logMessage)")
        }
    }
} 