//
//  AuditLogginProtocol.swift
//  MessageModel
//
//  Created by Martin Brude on 14/6/23.
//  Copyright © 2023 pEp Security S.A. All rights reserved.
//

import Foundation

/// Protocol that communicates MM with PlanckForiOS
/// The events to log happen in MM.
/// There are values we need from PlanckForiOS.
public protocol AuditLogginProtocol: AnyObject {

    /// Save the audit log.
    func log(timestamp: String, subject: String, senderId: String, rating: String)
}
