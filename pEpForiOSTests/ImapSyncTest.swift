//
//  ImapSyncTest.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 26/04/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import XCTest
import CoreData

import pEpForiOS

class TestImapSyncDelegate: DefaultImapSyncDelegate {
    var errorOccurred = false
    var connectionTimedOut = false
    var authSucess = false

    override init() {
    }

    override func authenticationFailed(notification: NSNotification?) {
        errorOccurred = true
    }

    override func connectionLost(notification: NSNotification?) {
        errorOccurred = true
    }

    override func connectionTerminated(notification: NSNotification?) {
        errorOccurred = true
    }

    override func connectionTimedOut(notification: NSNotification?) {
        connectionTimedOut = true
        errorOccurred = true
    }

    override func authenticationCompleted(notification: NSNotification?) {
        authSucess = true
    }
}

class ImapSyncTest: XCTestCase {
    var coreDataUtil: InMemoryCoreDataUtil!

    override func setUp() {
        super.setUp()
        coreDataUtil = InMemoryCoreDataUtil()
    }

    /**
     Runs the runloop until either some time has elapsed or a predicate is true.
     */
    func runloopFor(time: CFAbsoluteTime, until: () -> Bool) {
        let now = CFAbsoluteTimeGetCurrent()
        while CFAbsoluteTimeGetCurrent() - now < time && !until() {
            NSRunLoop.mainRunLoop().runMode(
                NSDefaultRunLoopMode, beforeDate: NSDate.distantFuture())
        }
    }

    func testConnectionFail() {
        let del = TestImapSyncDelegate.init()
        let conInfo = ConnectInfo.init(
            email: "", imapPassword: "", imapAuthMethod: "",
            smtpAuthMethod: "", imapServerName: "doesnot.work", imapServerPort: 5000,
            imapTransport: .Plain, smtpServerName: "", smtpServerPort: 5001, smtpTransport: .Plain)
        let sync = ImapSync.init(coreDataUtil: coreDataUtil, connectInfo: conInfo)
        sync.delegate = del
        sync.start()
        runloopFor(2, until: { return del.errorOccurred })
        XCTAssertTrue(del.errorOccurred)
        XCTAssertTrue(del.connectionTimedOut)
    }

    func testAuthSuccess() {
        let del = TestImapSyncDelegate.init()
        let conInfo = TestData()
        let sync = ImapSync.init(coreDataUtil: coreDataUtil, connectInfo: conInfo)
        sync.delegate = del
        sync.start()
        runloopFor(5, until: {
            print("del.errorOccurred \(del.errorOccurred) del.authSucess \(del.authSucess)")
            return del.errorOccurred || del.authSucess
        })
        XCTAssertTrue(!del.errorOccurred)
        XCTAssertTrue(del.authSucess)
    }
}
