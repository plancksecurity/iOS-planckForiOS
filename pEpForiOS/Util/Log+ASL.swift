//
//  Log+ASL.swift
//  pEp
//
//  Created by Dirk Zimmermann on 03.10.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import Foundation

class ASLLogger: ActualLoggerProtocol {
    func saveLog(severity: LoggingSeverity,
                 entity: String,
                 description: String,
                 comment: String) {
        let logMessage = asl_new(UInt32(ASL_TYPE_MSG))

        asl_set(logMessage, ASLLogger.keyEntityName, entity)
        asl_set(logMessage, ASL_KEY_FACILITY, ASLLogger.facilityName)
        asl_set(logMessage, ASL_KEY_MSG, description)
        asl_set(logMessage, ASL_KEY_LEVEL, "\(severity.aslLevel())")

        asl_send(nil, logMessage)

        asl_free(logMessage)
    }

    func retrieveLog() -> String {
        let query = asl_new(UInt32(ASL_TYPE_QUERY))

        let result = asl_set_query(query,
                                   ASL_KEY_FACILITY,
                                   ASLLogger.facilityName,
                                   UInt32(ASL_QUERY_OP_EQUAL))
        ASLLogger.checkASLSuccess(result: result, comment: "asl_set_query ASL_KEY_FACILITY")

        let response = asl_search(nil, query)
        var next = asl_next(response)
        var logString = ""
        while next != nil {
            if let stringPointer = asl_get(next, ASL_KEY_MSG),
                let entityNamePtr = asl_get(next, ASLLogger.keyEntityName) {
                // TODO: Also retrieve ASL_KEY_LEVEL?

                let entityName = String(cString: entityNamePtr)

                let theString = String(cString: stringPointer)
                if !logString.isEmpty {
                    logString.append("\n")
                }
                logString.append("*** \(entityName) \(theString)")
            }
            next = asl_next(response)
        }

        asl_free(query)

        return logString
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
