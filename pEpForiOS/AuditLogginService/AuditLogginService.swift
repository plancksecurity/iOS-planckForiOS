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
        AuditLoggingUtil.shared.log(senderId: senderId, rating: rating, maxLogTime: AppSettings.shared.auditLoggingTime) { error in
            UIUtils.show(error: error)
        }
    }

    static func log(event: AuditLoggerEvent) {
        AuditLoggingUtil.shared.logEvent(maxLogTime: AppSettings.shared.auditLoggingTime, auditLoggerEvent: event) { error in
            UIUtils.show(error: error)
        }
    }
}
