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
    
    var timestamp: String
    var subject: String
    var senderId: String
    var rating: String

    public var entry: String {
        return "\(timestamp), \(subject), \(senderId), \(rating)"
    }
}
