//
//  AuditLog.swift
//  MessageModel
//
//  Created by Martin Brude on 9/6/23.
//  Copyright © 2023 pEp Security S.A. All rights reserved.
//

import Foundation
import PlanckToolbox

public struct AuditLog {
    // Timestamp of the moment where the message was rated
    var timestamp: String
    // Email subject
    var subject: String
    // The email address
    var senderId: String
    // The email rating
    var rating: String
    // The CSV entry
    var entry: String {
        return "\(timestamp), \(subject), \(senderId), \(rating)"
    }
}
