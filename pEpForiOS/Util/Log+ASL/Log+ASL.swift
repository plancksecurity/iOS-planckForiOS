//
//  Log+ASL.swift
//  pEp
//
//  Created by Dirk Zimmermann on 03.10.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import Foundation

import CleanroomASL

class ASLLogger: ActualLoggerProtocol {
    let sender = "pEpForiOS"

    let client: ASLClient

    init() {
        self.client = ASLClient(
            filePath: nil, sender: sender, facility: "defaultFacility",
            filterMask: 0, useRawStdErr: false, openFileForWriting: false, options: .none)
    }

    func saveLog(severity: LoggingSeverity,
                 entity: String,
                 description: String,
                 comment: String) {
        let message = ASLMessageObject(
            priorityLevel: .notice,
            message: description)

        message[.facility] = entity

        client.log(message)
    }

    func retrieveLog(block: @escaping (String) -> Void) {
        let query = ASLQueryObject()

        query.setQuery(key: .message, value: nil, operation: .keyExists, modifiers: .none)
        query.setQuery(key: .sender, value: sender, operation: .equalTo, modifiers: .none)

        var theLog = ""
        client.search(query) { record in
            if let rec = record {
                theLog = theLog + (theLog.isEmpty ? "" : "\n") + "\(rec.timestamp) \(rec.message)"
            } else {
                block(theLog)
            }
            return true
        }
    }

    private static let facilityName = "security.pEp"
    private static let keyEntityName = "keyComponentName"

    private static func checkASLSuccess(result: Int32, comment: String) {
        if result != 0 {
            print("error: \(comment)")
        }
    }
}

extension LoggingSeverity {
    /**
     Maps the internal criticality of a log  message into a subsystem of ASL levels.

     ASL has the following:
     * ASL_LEVEL_EMERG
     * ASL_LEVEL_ALERT
     * ASL_LEVEL_CRIT
     * ASL_LEVEL_ERR
     * ASL_LEVEL_WARNING
     * ASL_LEVEL_NOTICE
     * ASL_LEVEL_INFO
     * ASL_LEVEL_DEBUG
     */
    func aslLevel() -> Int32 {
        switch self {
        case .verbose:
            return ASL_LEVEL_DEBUG
        case .info:
            return ASL_LEVEL_NOTICE
        case .warning:
            return ASL_LEVEL_WARNING
        case .error:
            return ASL_LEVEL_ERR
        }
    }
}

extension Int32 {
    func aslLevelString() -> String {
        switch self {
        case ASL_LEVEL_EMERG:
            return "ASL_LEVEL_EMERG"
        case ASL_LEVEL_ALERT:
            return "ASL_LEVEL_ALERT"
        case ASL_LEVEL_CRIT:
            return "ASL_LEVEL_CRIT"
        case ASL_LEVEL_ERR:
            return "ASL_LEVEL_ERR"
        case ASL_LEVEL_WARNING:
            return "ASL_LEVEL_WARNING"
        case ASL_LEVEL_NOTICE:
            return "ASL_LEVEL_NOTICE"
        case ASL_LEVEL_INFO:
            return "ASL_LEVEL_INFO"
        case ASL_LEVEL_DEBUG:
            return "ASL_LEVEL_DEBUG"
        default:
            return "ASL_LEVEL_UNKNOWN"
        }
    }
}
