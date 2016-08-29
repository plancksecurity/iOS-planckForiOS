//
//  Log.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 08/04/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import Foundation

/** Very primitive Logging class. */
@objc public class Log: NSObject, CWLogging {

    private static let disallow: Set<String> = []

    /** Somewhat verbose */
    static public func infoComponent(component: String, _ content: String) {
        if !disallow.contains(component) {
            print("\(component): \(content)")
        }
    }

    /** More important */
    static public func warnComponent(component: String, _ content: String) {
        if !disallow.contains(component) {
            print("\(component): \(content)")
        }
    }

    static public func errorComponent(component: String, error: NSError) {
        print("\(component): Error: \(error)")
    }

    static public func errorComponent(component: String, errorString: String) {
        print("\(component): \(errorString)")
    }

    @objc public func infoComponent(component: String!, message: String!) {
        Log.infoComponent(component, message)
    }

    @objc public func warnComponent(component: String!, message: String!) {
        Log.warnComponent(component, message)
    }
}