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
import MessageModel

/**
 Equality (==) for 3-tuples of optional Strings.
 */
func ==<T1: Equatable, T2: Equatable, T3: Equatable>(
    lhs: (T1?, T2?, T3?), rhs: (T1?, T2?, T3?)) -> Bool {
    return lhs.0 == rhs.0 && lhs.1 == rhs.1 && lhs.2 == rhs.2
}

class TestUtil {
    /**
     The maximum time most tests are allowed to run.
     */
    static let waitTime: TimeInterval = 20

    /**
     The maximum time model save tests are allowed to run.
     */
    static let modelSaveWaitTime: TimeInterval = 6

    /**
     The maximum time.
     */
    static let waitTimeForever: TimeInterval = 20000

    static let connectonShutDownWaitTime: TimeInterval = 1
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
            Thread.sleep(forTimeInterval: connectonShutDownWaitTime)
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
            Thread.sleep(forTimeInterval: connectonShutDownWaitTime)
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
        for bundle in Bundle.allBundles {
            dumpBundle(bundle)
        }

        let testBundle = Bundle.init(for: PEPSessionTest.self)
        dumpBundle(testBundle)
    }

    /**
     Print some essential properties of a bundle to the console.
     */
    static func dumpBundle(_ bundle: Bundle) {
        print("bundle \(bundle.bundleIdentifier) \(bundle.bundlePath)")
    }

    /**
     Import a key with the given file name from our own test bundle.
     - Parameter session: The pEp session to import the key into.
     - Parameter fileName: The file name of the key (complete with extension)
     */
    static func importKeyByFileName(_ session: PEPSession, fileName: String) {
        let testBundle = Bundle.init(for: PEPSessionTest.self)
        guard let keyPath = testBundle.path(forResource: fileName, ofType: nil) else {
            XCTAssertTrue(false, "Could not find key with file name \(fileName)")
            return
        }
        guard let data = try? Data.init(contentsOf: URL(fileURLWithPath: keyPath)) else {
            XCTAssertTrue(false, "Could not load key with file name \(fileName)")
            return
        }
        guard let content = NSString.init(data: data, encoding: String.Encoding.ascii.rawValue) else {
            XCTAssertTrue(false, "Could not convert key with file name \(fileName) into data")
            return
        }
        session.importKey(content as String)
    }

    static func loadDataWithFileName(_ fileName: String) -> Data? {
        let testBundle = Bundle.init(for: PEPSessionTest.self)

        guard let keyPath = testBundle.path(forResource: fileName, ofType: nil) else {
            XCTAssertTrue(false, "Could not find file named \(fileName)")
            return nil
        }
        guard let data = try? Data.init(contentsOf: URL(fileURLWithPath: keyPath)) else {
            XCTAssertTrue(false, "Could not load file named \(fileName)")
            return nil
        }
        return data
    }

    static func setupSomeIdentities(_ session: PEPSession)
        -> (identity: NSMutableDictionary, receiver1: PEPIdentity,
        receiver2: PEPIdentity, receiver3: PEPIdentity,
        receiver4: PEPIdentity) {
            let identity = NSMutableDictionary()
            identity[kPepUsername] = "Unit Test"
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

            return (identity, receiver1 as NSDictionary as! PEPIdentity,
                    receiver2 as NSDictionary as! PEPIdentity,
                    receiver3 as NSDictionary as! PEPIdentity,
                    receiver4 as NSDictionary as! PEPIdentity)
    }

    /**
     Recursively removes some (not so important) keys from dictionaries
     so they don't interfere with `isEqual`.
     */
    static func removeUnneededKeysForComparison(
        _ keys: [String], fromMail: PEPMessage) -> PEPMessage {
        var m: [String: AnyObject] = fromMail
        for k in keys {
            m.removeValue(forKey: k)
        }
        let keysToCheckRecursively = m.keys
        for k in keysToCheckRecursively {
            let value = m[k]
            if let dict = value as? PEPMessage {
                m[k] = removeUnneededKeysForComparison(keys, fromMail: dict) as AnyObject?
            }
        }
        return m
    }

    /**
     Dumps some diff between two NSDirectories to the console.
     */
    static func diffDictionaries(_ dict1: NSDictionary, dict2: NSDictionary) {
        for (k,v1) in dict1 {
            if let v2 = dict2[k as! NSCopying] {
                if !(v1 as AnyObject).isEqual(v2) {
                    print("Difference in '\(k)': '\(v2)' <-> '\(v1)'")
                }
            } else {
                print("Only in dict1: \(k)")
            }
        }
        for (k,_) in dict2 {
            if dict1[k as! NSCopying] == nil {
                print("Only in dict2: \(k)")
            }
        }
    }

    static func runAddressBookTest(_ testBlock: () -> (), addressBook: AddressBook,
                                   testCase: XCTestCase, waitTime: TimeInterval) {
        // We need authorization for this test to work
        if addressBook.authorizationStatus == .notDetermined {
            let exp = testCase.expectation(description: "granted")
            let _ = addressBook.authorize({ ab in
                exp.fulfill()
            })
            testCase.waitForExpectations(timeout: TestUtil.waitTime, handler: { error in
                XCTAssertNil(error)
                XCTAssertTrue(addressBook.authorizationStatus == .authorized)
            })
        } else {
            XCTAssertTrue(addressBook.authorizationStatus == .authorized)
        }
        testBlock()
    }

    /**
     Reusable implementation of `AccountDelegate` that just signals expectations.
     */
    class TestAccountDelegate: AccountDelegate {
        var expVerifyCalled: XCTestExpectation?
        var error: NSError?

        func didVerify(account: Account, error: NSError?) {
            self.error = error
            expVerifyCalled?.fulfill()
        }
    }

    /**
     Validates all servers and their credentials without actually validating them.
     */
    static func skipValidation() {
        guard let accs = CdAccount.all() as? [CdAccount] else {
            XCTAssertTrue(false)
            return
        }
        for acc in accs {
            acc.needsVerification = false
        }

        guard let servers = CdServer.all() as? [CdServer] else {
            XCTAssertTrue(false)
            return
        }
        for server in servers {
            guard let creds = server.credentials else {
                XCTAssertTrue(false)
                return
            }
            for c in creds {
                guard let cred = c as? CdServerCredentials else {
                    XCTAssertTrue(false)
                    return
                }
                cred.needsVerification = false
            }
        }
    }
}
