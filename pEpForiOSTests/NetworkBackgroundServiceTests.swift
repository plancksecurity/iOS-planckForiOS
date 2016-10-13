//
//  NetworkBackgroundServiceTests.swift
//  pEpForiOS
//
//  Created by hernani on 07/10/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import Foundation
import XCTest

import pEpForiOS

class NetworkBackgroundServiceTests: XCTestCase {
    let comp = "NetworkBackgroundServiceTests"
    var networkBackgroundService: NetworkBackgroundService!

    override func setUp() {
        super.setUp()
        networkBackgroundService = NetworkBackgroundService()
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    // Test service existence.
    func testExistenceNetworkBackgroundService() {
        XCTAssertNotNil(networkBackgroundService)
    }
   
    // Test GCD queue existence.
    func testExistenceBackgroundQueue() {
        XCTAssertTrue(networkBackgroundService.isBackgroundQueueExistent())
    }
    
    // Test basic ImapSync in background on start & cancel.
    func testImapConnection() {
        let connectInfo = TestData.connectInfo
        let imapBlock = DispatchWorkItem {
            let _ = ImapSync(connectInfo: connectInfo)
        }
        networkBackgroundService.doWork(workItem: imapBlock)
        XCTAssertFalse(imapBlock.isCancelled)
        imapBlock.cancel()
        XCTAssertTrue(imapBlock.isCancelled)
    }
    
    // XXX: Test reception of a crafted message through the CoreData layer.
    func testCoreDataMessageReception() {
        XCTAssertTrue(false)
    }
    
    // XXX: Test sending out a plain text message in CoreData format.
    func testSendCoreDataMessageUnencrypted() {
        XCTAssertTrue(false)
    }
    
    // XXX: Test sending
    func testSendCoreDataMessageEncrypted() {
        XCTAssertTrue(false)
    }
    
    

    /*
     * Not used currently.
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
    */

}
