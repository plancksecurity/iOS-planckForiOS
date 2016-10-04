//
//  SmtpTest.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 04/05/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import Foundation

import XCTest
import CoreData

import pEpForiOS

class SmtpTest: XCTestCase {
    func testSimpleAuth() {
        class MyDelegate: SmtpSendDefaultDelegate {
            var authenticatedExpectation: XCTestExpectation?
            override func authenticationCompleted(_ smtp: SmtpSend,
                                                  theNotification: Notification?) {
                authenticatedExpectation?.fulfill()
            }
        }
        let count = Service.refCounter.refCount
        for _ in 1...1 {
            var smtp: SmtpSend! = SmtpSend.init(connectInfo: TestData.connectInfo)
            let del = MyDelegate.init()
            del.authenticatedExpectation = expectation(description: "authenticatedExpectation")
            smtp.delegate = del
            smtp.start()
            waitForExpectations(timeout: TestUtil.waitTime, handler: { error in
                XCTAssertNil(error)
                // Adapt this for different servers
                XCTAssertEqual(smtp.bestAuthMethod(), AuthMethod.Login)
                smtp.close()
            })
            smtp = nil
        }
        XCTAssertEqual(Service.refCounter.refCount, count)
    }
}
