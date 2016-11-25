//
//  NetworkServiceTests.swift
//  pEpForiOS
//
//  Created by hernani on 23/11/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import XCTest

import MessageModel
import pEpForiOS

class NetworkServiceTests: XCTestCase {
    
    var persistenceSetup: PersistentSetup!
    
    let networkServiceBasic: NetworkService = NetworkService()
    var networkServiceSingleConnection: NetworkService!
    var networkServiceMultipleConnections: NetworkService!

    // For two examples of an inbond / outbond connection pair.
    var connectInfo1: (smtp: EmailConnectInfo?, imap: EmailConnectInfo?)
    var connectInfo2: (smtp: EmailConnectInfo?, imap: EmailConnectInfo?)
    var cdAccount1: CdAccount!
    var cdAccount2: CdAccount!
    
    override func setUp() {
        super.setUp()
        
        // Initialize Core Data layer.
        persistenceSetup = PersistentSetup()
        cdAccount1 = TestData().createWorkingCdAccount()
        cdAccount2 = TestData().createWorkingCdAccount(number: 2)
        Record.saveAndWait()
        
        connectInfo1 = (cdAccount1.smtpConnectInfo, cdAccount1.imapConnectInfo)
        connectInfo2 = (cdAccount2.smtpConnectInfo, cdAccount2.imapConnectInfo)
        
        networkServiceBasic.start()
    }
    
    override func tearDown() {
        super.tearDown()
        // Nothing yet.
    }
    
    func testNetworkServiceExistenceAfterStart() {
        XCTAssertFalse(networkServiceBasic.isMainThread)
        XCTAssertFalse(networkServiceBasic.isFinished)
    }
    
    func testNetworkServiceExistenceAfterCancel() {
        XCTAssertFalse(networkServiceBasic.isCancelled)
        networkServiceBasic.cancel()
        XCTAssertTrue(networkServiceBasic.isCancelled)
        // XXX: networkSerivce.isFinished can evaluate both, True and False. It usually takes some
        // seconds to happen. There's no exit() method anymore
        // (neither using Thread nor NSThread)  .
    }
    
    // stub
    func testNetworkServiceWithSingleConnection() {
        networkServiceSingleConnection = NetworkService(connectInfo: connectInfo1.imap!)
        networkServiceSingleConnection.start()
        XCTAssertFalse(networkServiceSingleConnection.isFinished)
    }
    
    // stub
    func testNetworkServiceWithMultipleConnections() {
        networkServiceMultipleConnections = NetworkService(connectInfos:
                                                          [connectInfo1.imap!, connectInfo2.imap!])
        networkServiceMultipleConnections.start()
        XCTAssertFalse(networkServiceMultipleConnections.isFinished)
    }
    
}
