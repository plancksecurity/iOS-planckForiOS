//
//  AuditLogUtil.swift
//  planckForiOS
//
//  Created by Martin Brude on 12/6/23.
//  Copyright © 2023 pEp Security S.A. All rights reserved.
//

import Foundation
import PlanckToolbox

public protocol AuditLoggingUtilProtocol: AnyObject {
    
    /// Save the log. 
    /// If the file exceeds the time bound, we will keep only the entries of the last days according to the max log time passed.
    func log(senderId: String, rating: String, maxLogTime: Int, errorCallback: @escaping (Error) -> Void)
    
    /// Save the event log (start, stop).
    /// If the file exceeds the time bound, we will keep only the entries of the last days according to the max log time passed.
    func logEvent(maxLogTime: Int, auditLoggerEvent: AuditLoggerEvent, errorCallback: @escaping (Error) -> Void)
}

public enum AuditLoggerEvent: String {
    case start = "Start"
    case stop = "Stop"
}

public class AuditLoggingUtil: NSObject, AuditLoggingUtilProtocol {

    private var fileExportUtil: FileExportUtilProtocol
    
    // MARK: - Singleton

    static public let shared = AuditLoggingUtil()
    
    init (fileExportUtil: FileExportUtilProtocol = FileExportUtil.shared) {
        self.fileExportUtil = fileExportUtil
    }
    
    /// Log `Start` and `Stop` events
    public func logEvent(maxLogTime: Int, auditLoggerEvent: AuditLoggerEvent, errorCallback: @escaping (Error) -> Void) {
        let log = EventLog([Date.timestamp, auditLoggerEvent.rawValue])
        save(log: log, maxLogTime: maxLogTime, errorCallback: errorCallback)
    }

    /// Log ratings
    public func log(senderId: String, rating: String, maxLogTime: Int, errorCallback: @escaping (Error) -> Void) {
        let log = EventLog([Date.timestamp, senderId, rating])
        save(log: log, maxLogTime: maxLogTime, errorCallback: errorCallback)
    }
}

// MARK: - Private

extension AuditLoggingUtil {

    private func save(log: EventLog, maxLogTime: Int, errorCallback: @escaping (Error) -> Void) {
        fileExportUtil.save(auditEventLog: log, maxLogTime: maxLogTime, errorCallback: errorCallback)
    }
}
