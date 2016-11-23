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
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testNetworkServiceExistence() {
        XCTAssertFalse(networkService.isMainThread)
        XCTAssertFalse(networkService.isFinished)
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
    
}
