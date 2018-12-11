//
//  Log+ASL.swift
//  pEp
//
//  Created by Dirk Zimmermann on 03.10.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import Foundation

/**
 - Note: The log file is currently not bounded in size. It lives in the caches directory,
 but still this will cause problems.
 */
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
        asl_set(logMessage, ASL_KEY_READ_UID, "-1")

        setupConsoleLogger()
        asl_send(self.consoleClient, logMessage)

        loggingQueue.async { [weak self] in
            if let theSelf = self {
                theSelf.setupFileLogger()
                asl_send(theSelf.fileClient, logMessage)
            }

            asl_free(logMessage)
        }
    }

    func retrieveLog() -> String {
        let query = asl_new(UInt32(ASL_TYPE_QUERY))

        let result = asl_set_query(query,
                                   ASL_KEY_SENDER,
                                   sender,
                                   UInt32(ASL_QUERY_OP_EQUAL))
        ASLLogger.checkASLSuccess(result: result, comment: "asl_set_query ASL_KEY_SENDER")

        let theClient = createFileLogger(readOrWrite: .read)

        let response = asl_search(theClient, query)
        var next = asl_next(response)
        var logString = ""
        while next != nil {
            if let stringMessage = asl_get(next, ASL_KEY_MSG),
                let entityNamePtr = asl_get(next, ASL_KEY_FACILITY),
                let levelPtr = asl_get(next, ASL_KEY_LEVEL) {
                let entityName = String(cString: entityNamePtr)
                let theMessage = String(cString: stringMessage)
                let levelRawString = String(cString: levelPtr)
                let level = levelRawString.aslLevelStringToASL()
                let ownLevelString = level.criticalityString()

                if !logString.isEmpty {
                    logString.append("\n")
                }

                let stringToLog = "[\(ownLevelString)] [\(entityName)] \(theMessage)"
                logString.append(stringToLog)
            }
            next = asl_next(response)
        }

        asl_free(query)
        asl_free(response)
        asl_free(theClient)

        return logString
    }

    /**
     Use this in a test, to wait for writing all scheduled logs.
     */
    func flush() {
        loggingQueue.sync {
            // nothing
        }
    }

    private let sender = "security.pEp.app.iOS"

    private var fileClient: aslclient?
    private var consoleClient: aslclient?
    private let loggingQueue = DispatchQueue(label: "security.pEp.logging")

    enum ReadOrWriteSupport {
        case write
        case read
    }

    private func setupConsoleLogger() {
        if consoleClient == nil {
            consoleClient = asl_open(self.sender, "default", 0)
        }
    }

    private func setupFileLogger() {
        if fileClient == nil {
            fileClient = createFileLogger(readOrWrite: .write)
        }
    }

    private func createFileLogger(readOrWrite: ReadOrWriteSupport) -> aslclient? {
        if let url = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).last {
            let logUrl = url.appendingPathComponent("ASLLog", isDirectory: false)
            return asl_open_path(
                logUrl.path,
                readOrWrite == .write ? UInt32(ASL_OPT_OPEN_WRITE | ASL_OPT_CREATE_STORE) : 0)
        } else {
            return nil
        }
    }

    deinit {
        asl_release(consoleClient)
        asl_release(fileClient)
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
