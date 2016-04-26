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
}

class ImapSyncTest: XCTestCase {
    var coreDataUtil: InMemoryCoreDataUtil!

    override func setUp() {
        super.setUp()
        coreDataUtil = InMemoryCoreDataUtil()
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
        let wait: CFAbsoluteTime = 2
        let now = CFAbsoluteTimeGetCurrent()
        while !del.errorOccurred && CFAbsoluteTimeGetCurrent() - now < wait {
            NSRunLoop.mainRunLoop().runMode(
                NSDefaultRunLoopMode, beforeDate: NSDate.distantFuture())
        }
        XCTAssertTrue(del.errorOccurred)
        XCTAssertTrue(del.connectionTimedOut)
    }
}
