//
//  AuditLog.swift
//  MessageModel
//
//  Created by Martin Brude on 9/6/23.
//  Copyright © 2023 pEp Security S.A. All rights reserved.
//

import Foundation
import PlanckToolbox
import pEp4iosIntern

public struct AuditLog {
    
    var timestamp: String
    var subject: String
    var senderId: String
    var rating: String
    
    public init(subject: String, senderId: String, rating: String) {
        self.timestamp = String(Date().timeIntervalSince1970)
        self.subject = subject
        self.senderId = senderId
        self.rating = rating
    }

    public init(timestamp: String, subject: String, senderId: String, rating: String) {
        self.init(subject: subject, senderId: senderId, rating: rating)
        self.timestamp = timestamp
    }

    public var entry: String {
        return "\(timestamp), \(subject), \(senderId), \(rating) \n"
    }
}
