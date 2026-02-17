import Foundation
import os.log

/// Unified logging for the app
enum PTTLogger {
    private static let subsystem = "com.openclaw.pushtotalk"
    private static let logger = Logger(subsystem: subsystem, category: "PTT")
    
    static func info(_ message: String) {
        logger.info("\(message)")
        #if DEBUG
        print("[INFO] \(message)")
        #endif
    }
    
    static func debug(_ message: String) {
        logger.debug("\(message)")
        #if DEBUG
        print("[DEBUG] \(message)")
        #endif
    }
    
    static func warning(_ message: String) {
        logger.warning("\(message)")
        #if DEBUG
        print("[WARN] \(message)")
        #endif
    }
    
    static func error(_ message: String) {
        logger.error("\(message)")
        #if DEBUG
        print("[ERROR] \(message)")
        #endif
    }
}
