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
    
    /// Save the log. If the file exceeds the time bound, the entries of the first day will be deleted.
    func log(senderId: String, rating: String, maxLogTime: Int)
}

public enum AuditLoggerEvent: String {
    case start = "Start"
    case stop = "Stop"
}

public class AuditLoggingUtil: NSObject, AuditLoggingUtilProtocol {
    
    private let savingLogsQueue: OperationQueue = {
        let createe = OperationQueue()
        createe.qualityOfService = .background
        createe.maxConcurrentOperationCount = 1
        createe.name = "security.planck.auditLoggging.queueForSavingLogs"
        return createe
    }()

    private var fileExportUtil: FileExportUtilProtocol
    
    // MARK: - Singleton

    static public let shared = AuditLoggingUtil()
    
    init (fileExportUtil: FileExportUtilProtocol = FileExportUtil.shared) {
        self.fileExportUtil = fileExportUtil
    }
    
    /// Logs starts and stops events
    public func logEvent(maxLogTime: Int, auditLoggerEvent: AuditLoggerEvent) {
        savingLogsQueue.addOperation {
            let log = EventLog([Date.timestamp, auditLoggerEvent.rawValue])
            self.fileExportUtil.save(auditEventLog: log, maxLogTime: maxLogTime)
        }
    }

    public func log(senderId: String, rating: String, maxLogTime: Int) {
        savingLogsQueue.addOperation {
            let log = EventLog([Date.timestamp, senderId, rating])
            self.fileExportUtil.save(auditEventLog: log, maxLogTime: maxLogTime)
        }
    }
}
