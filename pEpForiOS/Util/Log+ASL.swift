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
