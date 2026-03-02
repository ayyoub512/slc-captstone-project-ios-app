//
//  AppLogger.swift
//  VibeSync
//
//  Created by Ayyoub on 2/3/2026.
//

import OSLog

final class Log {
    
    static let shared = Log()
    
    private let logger: Logger
    
    private init() {
        logger = Logger(
            subsystem: Bundle.main.bundleIdentifier ?? "App",
            category: "General"
        )
    }
    
    func debug(_ message: String) {
        logger.debug("\(message)")
    }
    
    func info(_ message: String) {
        logger.info("\(message)")
    }
    
    func warning(_ message: String) {
        logger.warning("\(message)")
    }
    
    func error(_ message: String) {
        logger.error("\(message)")
    }
}
