//
//  AuditLoggingService.swift
//  planckForiOS
//
//  Created by Martin Brude on 14/6/23.
//  Copyright © 2023 p≡p Security S.A. All rights reserved.
//

import Foundation
#if EXT_SHARE
import MessageModelForAppExtensions
#else
import MessageModel
#endif

class AuditLoggingService: AuditLoggingProtocol {

    static public let shared = AuditLoggingService()

    init() {
        AuditLoggingService.log(event: .start)
    }

    func log(senderId: String, rating: String) {
        AuditLoggingUtil.shared.log(maxNumberOfDays: AppSettings.shared.auditLoggingMaxNumberOfDays, senderId: senderId, rating: rating) { error in
            UIUtils.show(error: error)
        }
    }

    static func log(event: AuditLoggerStartStopEvent) {
        AuditLoggingUtil.shared.logEvent(maxNumberOfDays: AppSettings.shared.auditLoggingMaxNumberOfDays, auditLoggerEvent: event) { error in
            UIUtils.show(error: error)
        }
    }
}
