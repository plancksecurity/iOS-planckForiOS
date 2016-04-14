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

    private static let allow: [String:Bool] = ["CWTCPConnection": true, "ImapSync": true,
                                       "SmtpSend": true]

    /** Somewhat verbose */
    static func info(component: String, _ content: String) {
        if allow[component] == true {
            print("\(component): \(content)")
        }
    }

    /** More important */
    static func warn(component: String, _ content: String) {
        if allow[component] == true {
            print("\(component): \(content)")
        }
    }

    static func error(component: String, error: NSError) {
        print("\(component): Error: \(error)")
    }

    @objc public func infoComponent(component: String!, message: String!) {
        Log.info(component, message)
    }

    @objc public func warnComponent(component: String!, message: String!) {
        Log.warn(component, message)
    }
}