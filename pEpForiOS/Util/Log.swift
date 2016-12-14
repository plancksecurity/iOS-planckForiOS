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

    static let shared: Log = {
        let instance = Log()
        return instance
    }()

    fileprivate override init() {
        super.init()}

    static open func verbose(component: String, content: String) {
        print("\(component): \(content)")
    }

    /** Somewhat verbose */
    static open func info(component: String, content: String) {
        print("\(component): \(content)")
    }

    /** More important */
    static open func warn(component: String, content: String) {
        print("\(component): \(content)")
    }

    static open func error(component: String, error: NSError?) {
        if let err = error {
            print("\(component): Error: \(err)")
        }
    }

    static open func error(component: String, errorString: String, error: NSError) {
        print("\(component): \(errorString): \(error)")
    }

    static open func error(component: String, errorString: String) {
        print("\(component): \(errorString)")
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
