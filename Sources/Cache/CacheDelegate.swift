//
//  CacheDelegate.swift
//  
//
//  Created by Dave Camp on 3/16/23.
//

import Foundation

/// Delegate type that can receive debugging and error information.
public protocol CacheDelegate: AnyObject {
    /// Log a debug message.
    /// - Parameters:
    ///   - message:    Message to be logged.
    ///   - error:      Optional error.
    func logDebugMessage(_ message: String, error: Error?)

    /// Log an error message,
    /// - Parameters:
    ///   - message:    Message to be logged.
    ///   - error:      Error that was encountered.
    func logErrorMessage(_ message: String, error: Error)
}

extension CacheDelegate {
    func logDebugMessage(_ message: String) {
        logDebugMessage(message, error: nil)
    }
}
