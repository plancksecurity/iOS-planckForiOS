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

        asl_set(logMessage, ASL_KEY_SENDER, sender)
        asl_set(logMessage, ASL_KEY_FACILITY, entity)
        asl_set(logMessage, ASL_KEY_MSG, "\(description) [\(comment)]")
        asl_set(logMessage, ASL_KEY_LEVEL, "\(severity.aslLevel())")

        let nowDate = Date()
        let dateString = "\(Int(nowDate.timeIntervalSince1970))"
        asl_set(logMessage, ASL_KEY_TIME, dateString)

        asl_set(logMessage, ASL_KEY_READ_UID, "-1")

        asl_send(self.consoleClient, logMessage)
        asl_free(logMessage)
    }

    func retrieveLog() -> String {
        let query = asl_new(UInt32(ASL_TYPE_QUERY))

        var result = asl_set_query(
            query,
            ASL_KEY_SENDER,
            sender,
            UInt32(ASL_QUERY_OP_EQUAL))
        ASLLogger.checkASLSuccess(result: result, comment: "asl_set_query ASL_KEY_SENDER")

        let fromDate = Date(timeInterval: -600, since: Date())
        let fromDateString = "\(Int(fromDate.timeIntervalSince1970))"
        result = asl_set_query(
            query,
            ASL_KEY_TIME,
            fromDateString,
            UInt32(ASL_QUERY_OP_GREATER_EQUAL))
        ASLLogger.checkASLSuccess(result: result, comment: "asl_set_query ASL_KEY_TIME")

        let theClient = createConsoleLogger()

        let response = asl_search(theClient, query)
        var next = asl_next(response)
        var logString = ""
        while next != nil {
            let timeString = String(cString: asl_get(next, ASL_KEY_TIME))
            let messageString = String(cString: asl_get(next, ASL_KEY_MSG))
            let facilityString = String(cString: asl_get(next, ASL_KEY_FACILITY))
            let levelString = String(cString: asl_get(next, ASL_KEY_LEVEL))

            let level = levelString.aslLevelStringToASL()
            let ownLevelString = level.criticalityString()

            var dateString = "<NoTime>"
            if let dateInt = Int(timeString) {
                let date = Date(timeIntervalSince1970: TimeInterval(dateInt))
                dateString = "\(date)"
            }

            if !logString.isEmpty {
                logString.append("\n")
            }

            let stringToLog = "\(dateString) [\(ownLevelString)] [\(facilityString)] \(messageString)"
            logString.append(stringToLog)

            next = asl_next(response)
        }

        asl_free(query)
        asl_free(response)
        asl_free(theClient)

        return logString
    }

    private let sender = "security.pEp.app.iOS"

    private var consoleClient: aslclient?

    private func createConsoleLogger() -> asl_object_t {
        return asl_open(self.sender, "default", 0)
    }

    init() {
        self.consoleClient = createConsoleLogger()
    }

    deinit {
        asl_release(consoleClient)
    }

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

extension String {
    func aslLevelStringToASL() -> Int32 {
        switch self {
        case "0":
            return ASL_LEVEL_EMERG
        case "1":
            return ASL_LEVEL_ALERT
        case "2":
            return ASL_LEVEL_CRIT
        case "3":
            return ASL_LEVEL_ERR
        case "4":
            return ASL_LEVEL_WARNING
        case "5":
            return ASL_LEVEL_NOTICE
        case "6":
            return ASL_LEVEL_INFO
        case "7":
            return ASL_LEVEL_DEBUG

        default:
            return ASL_LEVEL_DEBUG
        }
    }
}

extension Int32 {
    func criticalityString() -> String {
        switch self {
        case ASL_LEVEL_EMERG:
            return "EMERG"
        case ASL_LEVEL_ALERT:
            return "ALERT"
        case ASL_LEVEL_CRIT:
            return "CRIT"
        case ASL_LEVEL_ERR:
            return "ERR"
        case ASL_LEVEL_WARNING:
            return "WARNING"
        case ASL_LEVEL_NOTICE:
            return "NOTICE"
        case ASL_LEVEL_INFO:
            return "INFO"
        case ASL_LEVEL_DEBUG:
            return "DEBUG"
        default:
            return "UNKNOWN"
        }
    }

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
