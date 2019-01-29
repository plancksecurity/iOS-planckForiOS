//
//  MessageModelLogging.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 10/10/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import Foundation

/**
 The protocol this framework expects for logging.
 */
public protocol MessageModelLogging {
    func info(component: String, content: String)
    func verbose(component: String, content: String)
    func warn(component: String, content: String)
    func error(component: String, error: Error)
    func error(component: String, errorString: String, error: Error)
    func error(component: String, errorString: String)
    func errorAndCrash(component: String, error: Error)
    func errorAndCrash(component: String, errorString: String, error: Error)
    func errorAndCrash(component: String, errorString: String)
}

public class PrintLogger: MessageModelLogging {

    public init () {

    }
    
    public func verbose(component: String, content: String) {
        print("A VERBOSE \(component): \(content)")
    }

    public func info(component: String, content: String) {
        print("INFO \(component): \(content)")
    }

    public func warn(component: String, content: String) {
        print("WARN \(component): \(content)")
    }

    public func error(component: String, error: Error) {
        print("ERROR \(component): \(error.localizedDescription)")
    }


    public func error(component: String, errorString: String, error: Error) {
        print("ERROR \(component): \(errorString): \(error.localizedDescription)")
    }

    public func error(component: String, errorString: String) {
        print("ERROR \(component): \(errorString)")
    }

    /// Logs component and error.
    ///
    /// - note: If (and only if) in DEBUG configuration, it also calls fatalError().
    ///
    /// - Parameters:
    ///   - component: caller information to log
    ///   - error: error to log
    public func errorAndCrash(component: String, error: Error) {
        SystemUtils.crash("ERROR \(component): \(error.localizedDescription)")
    }

    /// Logs component, error message and error.
    ///
    /// - note: If (and only if) in DEBUG configuration, it also calls fatalError().
    ///
    /// - Parameters:
    ///   - component: caller information to log
    ///   - errorString: error information to log
    ///   - error: error to log
    public func errorAndCrash(component: String, errorString: String, error: Error) {
        SystemUtils.crash("ERROR \(component): \(errorString): \(error.localizedDescription)")
    }

    /// Logs component and error message.
    ///
    /// - note: If (and only if) in DEBUG configuration, it also calls fatalError().
    ///
    /// - Parameters:
    ///   - component: caller information to log
    ///   - errorString: error information to log
    public func errorAndCrash(component: String, errorString: String) {
        SystemUtils.crash("ERROR \(component): \(errorString)")
    }
}
