//
//  AuditLogginService.swift
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

class AuditLogginService: AuditLogginProtocol {
    
    static public let shared = AuditLogginService()

    func log(timestamp: String, subject: String, senderId: String, rating: String) {
        let maxLogSize = MDMUtil.isEnabled() ? AppSettings.shared.mdmAuditLogginMaxFileSize : AppSettings.shared.auditLogginSize
        AuditLogUtil.shared.log(timestamp: timestamp, subject: subject, senderId: senderId, rating: rating, maxLogSize: maxLogSize)
    }
}
