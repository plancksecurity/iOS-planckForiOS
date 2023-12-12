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
    /// We will only save entries from the last few days. The number of days are those indicated in the maxNumberOfDays parameter.
    /// E.g. If 30 is passed, entries older than 30 days will be discarded.
    func log(maxNumberOfDays: Int, senderId: String, rating: String, errorCallback: @escaping (Error) -> Void)
    
    /// Save the event log (start, stop).
    /// We will only save entries from the last few days. The number of days are those indicated in the maxNumberOfDays parameter.
    /// E.g. If 30 is passed, entries older than 30 days will be discarded.
    func logEvent(maxNumberOfDays: Int, auditLoggerEvent: AuditLoggerStartStopEvent, errorCallback: @escaping (Error) -> Void)
}

public enum AuditLoggerStartStopEvent: String {
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
    public func logEvent(maxNumberOfDays: Int, auditLoggerEvent: AuditLoggerStartStopEvent, errorCallback: @escaping (Error) -> Void) {
        let log = EventLog([Date.timestamp, auditLoggerEvent.rawValue])
        save(log: log, maxNumberOfDays: maxNumberOfDays, errorCallback: errorCallback)
    }

    /// Log ratings
    public func log(maxNumberOfDays: Int, senderId: String, rating: String, errorCallback: @escaping (Error) -> Void) {
        let log = EventLog([Date.timestamp, senderId, rating])
        save(log: log, maxNumberOfDays: maxNumberOfDays, errorCallback: errorCallback)
    }
}

// MARK: - Private

extension AuditLoggingUtil {

    private func save(log: EventLog, maxNumberOfDays: Int, errorCallback: @escaping (Error) -> Void) {
        fileExportUtil.save(auditEventLog: log, maxNumberOfDays: maxNumberOfDays, errorCallback: errorCallback)
    }
}
