//
//  AuditLogUtil.swift
//  planckForiOS
//
//  Created by Martin Brude on 12/6/23.
//  Copyright © 2023 pEp Security S.A. All rights reserved.
//

import Foundation

public protocol AuditLogUtilProtocol: AnyObject {
    
    /// Save the log. If the file exceeds the limit size, the first entry of the log file will be deleted.
    func log(subject: String, senderId: String, rating: String, maxLogSize: Double)
}

public class AuditLogUtil: NSObject, AuditLogUtilProtocol {
    
    private let savingLogsQueue: OperationQueue = {
        let createe = OperationQueue()
        createe.qualityOfService = .background
        createe.maxConcurrentOperationCount = 1
        createe.name = "security.planck.auditLog.queueForSavingLogs"
        return createe
    }()

    private var fileExportUtil: FileExportUtilProtocol
    
    // MARK: - Singleton

    static public let shared = AuditLogUtil()
    
    init (fileExportUtil: FileExportUtilProtocol = FileExportUtil.shared) {
        self.fileExportUtil = fileExportUtil
    }

    public func log(subject: String, senderId: String, rating: String, maxLogSize: Double) {
        savingLogsQueue.addOperation { [weak self] in
            guard let me = self else {
                //Valid case, nothing to do.
                return
            }
            let auditLog = AuditLog(subject: subject, senderId: senderId, rating: rating)
            me.fileExportUtil.save(auditLog: auditLog, maxLogSize: maxLogSize)
        }
    }
}
