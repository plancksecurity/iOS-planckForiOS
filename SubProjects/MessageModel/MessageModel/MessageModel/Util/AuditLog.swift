//
//  AuditLog.swift
//  MessageModel
//
//  Created by Martin Brude on 9/6/23.
//  Copyright © 2023 pEp Security S.A. All rights reserved.
//

import Foundation
import PlanckToolbox

// Represents an entry
public struct EventLog {
    
    init(_ content: [String]) {
        self.content = content
    }

    public private(set) var content: [String] = []
    
    mutating func add(_ newContent: String...) {
        content.append(contentsOf: newContent)
    }
    
    var entry: String {
        return content.map { $0 } .joined(separator: ", ")
    }

}
