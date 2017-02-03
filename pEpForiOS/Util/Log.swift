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
    lazy private var session = PEPSession()
    private var logEnabled = true
    private let queue = DispatchQueue(label: "logging")

    static open let shared: Log = {
        let instance = Log()
        return instance
    }()

    fileprivate override init() {
        super.init()
    }

    private func saveLog(entity: String, description: String, comment: String) {
        queue.async {
            if self.logEnabled {
                #if DEBUG_LOGGING
                    print("\(entity): \(description)")
                    self.session.logTitle(
                        self.title, entity: entity, description: description, comment: comment)
                #else
                    self.session.logTitle(
                        self.title, entity: entity, description: description, comment: comment)
                #endif
            }
        }
    }
    static open func disableLog() {
        Log.shared.queue.async {
            Log.shared.logEnabled = false
        }
    }

    static open func enableLog() {
        Log.shared.queue.async {
            Log.shared.logEnabled = true
        }
    }

    static open func isenabled() -> Bool {
        return Log.shared.logEnabled
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

    static open func error(component: String, error: NSError?) {
        if let err = error {
            Log.shared.saveLog(entity: component, description: " \(err)", comment: "error")
        }
    }

    static open func error(component: String, errorString: String, error: NSError) {
        Log.shared.saveLog(
            entity: component, description: errorString + " \(error)", comment: "error")
    }

    static open func error(component: String, errorString: String) {
        Log.shared.saveLog(entity: component, description: errorString, comment: "error")
    }

    static open func getlog() -> String {
        return Log.shared.session.getLog()
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

    public func error(component: String, error: NSError) {
        Log.error(component: component, error: error)
    }

    public func error(component: String, errorString: String, error: NSError) {
        Log.error(component: component, errorString: errorString, error: error)
    }

    public func error(component: String, errorString: String) {
        Log.error(component: component, errorString: errorString)
    }
}
