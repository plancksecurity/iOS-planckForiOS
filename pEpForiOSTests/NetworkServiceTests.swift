//
//  NetworkServiceTests.swift
//  pEpForiOS
//
//  Created by hernani on 23/11/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import XCTest

import pEpForiOS

class NetworkServiceTests: XCTestCase {
    
    let networkService: NetworkService = NetworkService()
    
    override func setUp() {
        super.setUp()
        networkService.start()
    }
    
    override func tearDown() {
        super.tearDown()
        // Nothing yet.
    }
    
    func testNetworkServiceExistenceAfterStart() {
        XCTAssertFalse(networkService.isMainThread)
        XCTAssertFalse(networkService.isFinished)
    }
    
    func testNetworkServiceExistenceAfterCancel() {
        XCTAssertFalse(networkService.isCancelled)
        networkService.cancel()
        XCTAssertTrue(networkService.isCancelled)
        // XXX: networkSerivce.isFinished can evaluate both, True and False. It usually takes some
        // seconds to happen. There's no more exit() method anymore.
    }
    
}
