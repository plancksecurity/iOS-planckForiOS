//
//  TestUtil.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 30/05/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import Foundation
import XCTest

import pEpForiOS

class TestUtil {
    static let connectonShutDownWaitTime: NSTimeInterval = 1
    static let numberOfTriesConnectonShutDown = 5

    static var initialNumberOfRunningConnections = 0
    static var initialNumberOfServices = 0

    /**
     In case there are other connections open, call this function before relying on
     `waitForConnectionShutdown` or `waitForServiceCleanup`
     */
    static func adjustBaseLevel() {
        initialNumberOfRunningConnections = CWTCPConnection.numberOfRunningConnections()
        initialNumberOfServices = Service.refCounter.refCount
    }

    /**
     Waits and verifies that all connection threads are finished.
     */
    static func waitForConnectionShutdown() {
        for _ in 1...numberOfTriesConnectonShutDown {
            if CWTCPConnection.numberOfRunningConnections() == initialNumberOfRunningConnections {
                break
            }
            NSThread.sleepForTimeInterval(connectonShutDownWaitTime)
        }
        // This only works if there are no accounts configured in the app.
        XCTAssertEqual(CWTCPConnection.numberOfRunningConnections(),
                       initialNumberOfRunningConnections)
    }

    /**
     Waits and verifies that all service objects (IMAP, SMTP) are finished.
     */
    static func waitForServiceCleanup() {
        for _ in 1...numberOfTriesConnectonShutDown {
            if Service.refCounter.refCount == initialNumberOfServices {
                break
            }
            NSThread.sleepForTimeInterval(connectonShutDownWaitTime)
        }
        // This only works if there are no accounts configured in the app.
        XCTAssertEqual(Service.refCounter.refCount, initialNumberOfServices)
    }

    /**
     Waits and verifies that all service objects are properly shutdown and cleaned up.
     */
    static func waitForServiceShutdown() {
        TestUtil.waitForConnectionShutdown()
        TestUtil.waitForServiceCleanup()
    }

    /**
     Some code for accessing `NSBundle`s from Swift.
     */
    static func showBundles() {
        for bundle in NSBundle.allBundles() {
            dumpBundle(bundle)
        }

        let testBundle = NSBundle.init(forClass: PEPSessionTest.self)
        dumpBundle(testBundle)
    }

    /**
     Print some essential properties of a bundle to the console.
     */
    static func dumpBundle(bundle: NSBundle) {
        print("bundle \(bundle.bundleIdentifier) \(bundle.bundlePath)")
    }

    /**
     Import a key with the given file name from our own test bundle.
     - Parameter session: The pEp session to import the key into.
     - Parameter fileName: The file name of the key (complete with extension)
     */
    static func importKeyByFileName(session: PEPSession, fileName: String) {
        let testBundle = NSBundle.init(forClass: PEPSessionTest.self)
        guard let keyPath = testBundle.pathForResource(fileName, ofType: nil) else {
            XCTAssertTrue(false, "Could not find key with file name \(fileName)")
            return
        }
        guard let data = NSData.init(contentsOfFile: keyPath) else {
            XCTAssertTrue(false, "Could not load key with file name \(fileName)")
            return
        }
        guard let content = NSString.init(data: data, encoding: NSASCIIStringEncoding) else {
            XCTAssertTrue(false, "Could not convert key with file name \(fileName) into data")
            return
        }
        session.importKey(content as String)
    }

    static func setupSomeIdentities(session: PEPSession)
        -> (identity: NSMutableDictionary, receiver1: PEPContact,
        receiver2: PEPContact, receiver3: PEPContact,
        receiver4: PEPContact) {
            let identity = NSMutableDictionary()
            identity[kPepUsername] = "myself"
            identity[kPepAddress] = "somewhere@overtherainbow.com"

            let receiver1 = NSMutableDictionary()
            receiver1[kPepUsername] = "receiver1"
            receiver1[kPepAddress] = "receiver1@shopsmart.com"

            let receiver2 = NSMutableDictionary()
            receiver2[kPepUsername] = "receiver2"
            receiver2[kPepAddress] = "receiver2@shopsmart.com"

            let receiver3 = NSMutableDictionary()
            receiver3[kPepUsername] = "receiver3"
            receiver3[kPepAddress] = "receiver3@shopsmart.com"

            let receiver4 = NSMutableDictionary()
            receiver4[kPepUsername] = "receiver4"
            receiver4[kPepAddress] = "receiver4@shopsmart.com"

            return (identity, receiver1 as PEPContact, receiver2 as PEPContact,
                    receiver3 as PEPContact, receiver4 as PEPContact)
    }

    /**
     Removes some (not so important) keys recursively from dictionaries
     so they don't interfere with `isEqual`.
     */
    static func removeUnneededKeysForComparison(
        keys: [String], fromMail: NSDictionary) -> NSDictionary {
        let m = fromMail.mutableCopy() as! NSMutableDictionary
        for k in keys {
            m.removeObjectForKey(k)
        }
        var replacements: [(NSCopying, NSCopying)] = []
        for (k, v) in m {
            if v.isKindOfClass(NSDictionary) {
                replacements.append((k as! NSCopying,
                    removeUnneededKeysForComparison(keys, fromMail: v as! NSDictionary)))
            } else if v.isKindOfClass((NSArray)) {
                let ar = v as! NSArray
                let fn: AnyObject -> AnyObject = { element in
                    if element.isKindOfClass(NSDictionary) {
                        return self.removeUnneededKeysForComparison(
                            keys, fromMail: element as! NSDictionary)
                    } else {
                        return element
                    }
                }
                let newArray = ar.map(fn)
                replacements.append((k as! NSCopying, newArray))
            }
        }
        for (k, v) in replacements {
            m[k] = v
        }
        return m as NSDictionary
    }

    /**
     Dumps some diff between two NSDirectories to the console.
     */
    static func diffDictionaries(dict1: NSDictionary, dict2: NSDictionary) {
        for (k,v1) in dict1 {
            if let v2 = dict2[k as! NSCopying] {
                if !v1.isEqual(v2) {
                    print("Difference in '\(k)': '\(v2)' <-> '\(v1)'")
                }
            } else {
                print("Only in pepMail: \(k)")
            }
        }
    }

    static func runAddressBookTest(testBlock: () -> (), addressBook: AddressBook,
                                   testCase: XCTestCase, waitTime: NSTimeInterval) {
        // We need authorization for this test to work
        if addressBook.authorizationStatus == .NotDetermined {
            let exp = testCase.expectationWithDescription("granted")
            addressBook.authorize({ ab in
                exp.fulfill()
            })
            testCase.waitForExpectationsWithTimeout(waitTime, handler: { error in
                XCTAssertNil(error)
                XCTAssertTrue(addressBook.authorizationStatus == .Authorized)
                testBlock()
            })
        } else {
            XCTAssertTrue(addressBook.authorizationStatus == .Authorized)
            testBlock()
        }
    }
}