//
//  AuditLogginProtocol.swift
//  MessageModel
//
//  Created by Martin Brude on 14/6/23.
//  Copyright © 2023 pEp Security S.A. All rights reserved.
//

import Foundation


public protocol AuditLogginProtocol: AnyObject {

    /// Save the audit log.
    func log(subject: String, senderId: String, rating: String)
}
