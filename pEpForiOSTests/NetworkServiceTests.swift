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
    
    let networkServiceBasic: NetworkService = NetworkService()
    var networkServiceSingleConnection: NetworkService!
    var networkServiceMultipleConnections: NetworkService!
    var persistenceSetup: PersistentSetup!
    
    // For a first example of an inbond / outbond connection pair.
    var cdAccount1: CdAccount!
    var imapConnectInfo1: EmailConnectInfo!
    var smtpConnectInfo1: EmailConnectInfo!
    
    // For a second example of an inbond / outbond connection pair.
    var cdAccount2: CdAccount!
    var imapConnectInfo2: EmailConnectInfo!
    var smtpConnectInfo2: EmailConnectInfo!
    
    override func setUp() {
        super.setUp()
        persistenceSetup = PersistentSetup()
        cdAccount1 = TestData().createWorkingCdAccount()
        cdAccount2 = TestData().createWorkingCdAccount(number: 2)
        Record.saveAndWait()
        
        imapConnectInfo1 = cdAccount1.imapConnectInfo
        imapConnectInfo2 = cdAccount2.imapConnectInfo
        
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
        // seconds to happen. There's no exit() method anymore (neither using Thread nor NSThread)  .
    }
    
    // stub
    func testNetworkServiceWithSingleConnection() {
        networkServiceSingleConnection = NetworkService(connectInfo: imapConnectInfo1)
        networkServiceSingleConnection.start()
        XCTAssertFalse(networkServiceSingleConnection.isFinished)
    }
    
    // stub
    func testNetworkServiceWithMultipleConnections() {
        networkServiceMultipleConnections = NetworkService(connectInfos:
                                                          [imapConnectInfo1, imapConnectInfo2])
        networkServiceMultipleConnections.start()
        XCTAssertFalse(networkServiceMultipleConnections.isFinished)
    }
    
}
