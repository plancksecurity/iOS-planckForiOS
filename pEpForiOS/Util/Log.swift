//
//  Log.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 08/04/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import MessageModel

/** Very primitive Logging class. */
@objc open class Log: NSObject {
    enum Severity {
        case verbose
        case info
        case warning
        case error
    }

    static public let shared: Log = {
        let instance = Log()
        return instance
    }()

    static public func disableLog() {
        Log.shared.loggingQueue.addOperation() {
            Log.shared.logEnabled = false
        }
    }

    static public func enableLog() {
        Log.shared.loggingQueue.addOperation() {
            Log.shared.logEnabled = true
        }
    }

    static public func checkEnabled(_ block: ((Bool) -> ())?) {
        Log.shared.loggingQueue.addOperation() {
            let b = Log.shared.logEnabled
            block?(b)
        }
    }

    static public func checklog(_ block: ((String?) -> ())?) {
        Log.shared.loggingQueue.addOperation() {
            if let logString = try? PEPSession().getLog() {
                block?(logString)
            } else {
                block?("")
            }
        }
    }

    static public func verbose(component: String, content: String) {
        Log.shared.saveLog(severity:.verbose,
                           entity: component, description: content, comment: "verbose")
    }

    /** Somewhat verbose */
    static public func info(component: String, content: String) {
        Log.shared.saveLog(severity:.info,
                           entity: component, description: content, comment: "info")
    }

    /** More important */
    static public func warn(component: String, content: String) {
        Log.shared.saveLog(severity:.warning,
                           entity: component, description: content, comment: "warn")
    }

    static public func error(component: String, error: Error?) {
        if let err = error {
            Log.shared.saveLog(severity:.error,
                               entity: component, description: " \(err)", comment: "error")
        }
    }

    static public func error(component: String, errorString: String, error: Error) {
        Log.shared.saveLog(severity:.error,
            entity: component, description: "\(errorString) \(error)", comment: "error")
    }

    static public func error(component: String, errorString: String) {
        Log.shared.saveLog(severity:.error,
                           entity: component, description: errorString, comment: "error")
    }

    public static func log(comp: String, mySelf: AnyObject, functionName: String) {
        let selfDesc = unsafeBitCast(mySelf, to: UnsafeRawPointer.self)
        Log.shared.info(component: comp, content: "\(functionName): \(selfDesc)")
    }

    public func resume() {
        Log.shared.paused = false
    }

    public func pause() {
        Log.shared.paused = true
        Log.shared.loggingQueue.cancelAllOperations()
    }

    private let title = "pEpForiOS"
    private var logEnabled = true
    private var paused = false

    private let loggingQueue: OperationQueue = {
        let createe = OperationQueue()
        createe.qualityOfService = .background
        createe.maxConcurrentOperationCount = 1
        return createe
    }()

    /**
     Prints or saves a log entry.
     - Note: For a log to be printed, the entity must be contained in `allowedEntities`,
     or the severity must be noted in `allowedSeverities`.
     */
    private func saveLog(severity: Severity,
                         entity: String,
                         description: String,
                         comment: String) {
        let allowedEntities = Set<String>(["CWIMAPStore", "ImapSync"])
        let allowedSeverities = Set<Severity>([.error, .warning, .info])

        if allowedSeverities.contains(severity) || allowedEntities.contains(entity) {
            let logMessage = asl_new(UInt32(ASL_TYPE_MSG))

            asl_set(logMessage, ASL_KEY_FACILITY, "security.pEp.\(entity)")
            asl_set(logMessage, ASL_KEY_MSG, description)
            asl_set(logMessage, ASL_KEY_LEVEL, "\(ASL_LEVEL_INFO)")

            asl_send(nil, logMessage)
        }
    }

    private func checkASLSuccess(result: Int32, comment: String) {
        if result != 0 {
            print("error: \(comment)")
        }
    }
}

extension Log: MessageModelLogging {
    public func verbose(component: String, content: String) {
        Log.verbose(component: component, content: content)
    }

    public func info(component: String, content: String) {
        Log.info(component: component, content: content)
    }

    public func warn(component: String, content: String) {
        Log.warn(component: component, content: content)
    }

    public func error(component: String, error: Error) {
        Log.error(component: component, error: error)
    }

    public func error(component: String, errorString: String, error: Error) {
        Log.error(component: component, errorString: errorString, error: error)
    }

    public func error(component: String, errorString: String) {
        Log.error(component: component, errorString: errorString)
    }

    /// Logs component and error.
    ///
    /// - note: If (and only if) in DEBUG configuration, it also calls fatalError().
    ///
    /// - Parameters:
    ///   - component: caller information to log
    ///   - error: error to log
    public func errorAndCrash(component: String, error: Error) {
        Log.error(component: component, error: error)
        SystemUtils.crash("ERROR \(component): \(error.localizedDescription)")
    }

    /// Logs component and error.
    ///
    /// - note: If (and only if) in DEBUG configuration, it also calls fatalError().
    ///
    /// - Parameters:
    ///   - component: caller information to log
    ///   - errorString: error information to log
    ///   - error: error to log
    public func errorAndCrash(component: String, errorString: String, error: Error) {
        Log.error(component: component, errorString: errorString, error: error)
        SystemUtils.crash("ERROR \(component): \(errorString): \(error.localizedDescription)")
    }

    /// Logs component and error.
    ///
    /// - note: If (and only if) in DEBUG configuration, it also calls fatalError().
    ///
    /// - Parameters:
    ///   - component: caller information to log
    ///   - errorString: error information to log
    public func errorAndCrash(component: String, errorString: String) {
        Log.error(component: component, errorString: errorString)
        SystemUtils.crash("ERROR \(component): \(errorString)")
    }
}

extension Log: CWLogging {
    @objc open func infoComponent(_ component: String, message: String) {
        Log.info(component: component, content: message)
    }

    @objc open func warnComponent(_ component: String, message: String) {
        Log.warn(component: component, content: message)
    }

    @objc open func errorComponent(_ component: String, message: String) {
        Log.error(component: component, errorString: message)
    }
}
