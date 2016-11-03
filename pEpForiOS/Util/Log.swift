//
//  Log.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 08/04/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import Foundation

/** Very primitive Logging class. */
@objc open class Log: NSObject, CWLogging {

    fileprivate static let disallow: Set<String> = []

    /** Somewhat verbose */
    static open func info(component: String, _ content: String) {
        if !disallow.contains(component) {
            print("\(component): \(content)")
        }
    }

    /** More important */
    static open func warn(component: String, _ content: String) {
        if !disallow.contains(component) {
            print("\(component): \(content)")
        }
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

    @objc open func infoComponent(_ component: String!, message: String!) {
        Log.info(component: component, message)
    }

    @objc open func warnComponent(_ component: String!, message: String!) {
        Log.warn(component: component, message)
    }
}
