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
    private let title = "pEpForiOS"
    private var logEnabled = true
    private var paused = false
    private let session = PEPSession()
    private let loggingQueue: OperationQueue = {
       let createe = OperationQueue()
        createe.qualityOfService = .background
        createe.maxConcurrentOperationCount = 1
        return createe
    }()

    static open let shared: Log = {
        let instance = Log()
        return instance
    }()

    private func saveLog(entity: String, description: String, comment: String) {
        #if DEBUG_LOGGING
            // If running in the debugger, dump to the console right away
            print("\(entity): \(description)")
        #endif
        if !MiscUtil.isUnitTest() {
            loggingQueue.addOperation() {
                if self.logEnabled && !self.paused {
                    do {
                        try self.session.logTitle(
                            self.title, entity: entity, description: description, comment: comment)
                    } catch {
                        // Ignore. In debug mode we have already logged,
                        // otherwise there's no point of logging "cannot log".
                    }
                }
            }
        }
    }

    func resume() {
        Log.shared.paused = false
    }

    func pause() {
        Log.shared.paused = true
        Log.shared.loggingQueue.cancelAllOperations()
    }

    static open func disableLog() {
        Log.shared.loggingQueue.addOperation() {
            Log.shared.logEnabled = false
        }
    }

    static open func enableLog() {
        Log.shared.loggingQueue.addOperation() {
            Log.shared.logEnabled = true
        }
    }

    static open func checkEnabled(_ block: ((Bool) -> ())?) {
        Log.shared.loggingQueue.addOperation() {
            let b = Log.shared.logEnabled
            block?(b)
        }
    }

    static open func checklog(_ block: ((String?) -> ())?) {
        Log.shared.loggingQueue.addOperation() {
            if let logString = try? PEPSession().getLog() {
                block?(logString)
            } else {
                block?("")
            }
        }
    }

    static open func verbose(component: String, content: String) {
        Log.shared.saveLog(entity: component, description: content, comment: "verbose")
    }

    /** Somewhat verbose */
    static open func info(component: String, content: String) {
        Log.shared.saveLog(entity: component, description: content, comment: "info")
    }

    /** More important */
    static open func warn(component: String, content: String) {
        Log.shared.saveLog(entity: component, description: content, comment: "warn")
    }

    static open func error(component: String, error: Error?) {
        if let err = error {
            Log.shared.saveLog(entity: component, description: " \(err)", comment: "error")
        }
    }

    static open func error(component: String, errorString: String, error: Error) {
        Log.shared.saveLog(
            entity: component, description: "\(errorString) \(error)", comment: "error")
    }

    static open func error(component: String, errorString: String) {
        Log.shared.saveLog(entity: component, description: errorString, comment: "error")
    }

    static func log(comp: String, mySelf: AnyObject, functionName: String) {
        let selfDesc = unsafeBitCast(mySelf, to: UnsafeRawPointer.self)
        Log.shared.info(component: comp, content: "\(functionName): \(selfDesc)")
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
        SystemUtils.crash("🔥 ERROR \(component): \(error.localizedDescription)")
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
        SystemUtils.crash("🔥 ERROR \(component): \(errorString): \(error.localizedDescription)")
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
        SystemUtils.crash("🔥 ERROR \(component): \(errorString)")
    }
}
