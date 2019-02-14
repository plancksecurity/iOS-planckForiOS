//
//  ReachabilityUtilsTests.swift
//  pEpForiOSTests
//
//  Created by Alejandro Gelos on 12/02/2019.
//  Copyright © 2019 p≡p Security S.A. All rights reserved.
//

import XCTest
@testable import pEpForiOS

class ReachibilityUtilsTests: XCTestCase {
    
    private var yesReachability: Reachability?
    private var noReachability:  Reachability?
    private let yesInternetNetworkReachibilityMock = YesInternetNetworkReachibilityMock()
    private let noInternetNetworkReachibilityMock  = NoInternetNetworkReachibilityMock()
    
    override func setUp() {
        yesReachability = Reachability(networkReachability: yesInternetNetworkReachibilityMock)
        noReachability  = Reachability(networkReachability: noInternetNetworkReachibilityMock)
    }
    
    override func tearDown() {
        yesReachability = nil
        noReachability  = nil
        super.tearDown()
    }
    
    func testGetConnectionStatusYesInternet() {
        // Given
        // Then
        guard let result = try? yesReachability?.getConnectionStatus() else{
            XCTFail("should not get nil in getConnectionStatus")
            return
        }
        // Then
        XCTAssertTrue(result == Reachability.Connection.connected)
    }
    
    func testGetConnectionStatusNoInternet() {
        // Given
        // When
        guard let result = try? noReachability?.getConnectionStatus() else{
            XCTFail("should not get nil in getConnectionStatus")
            return
        }
        // Then
        XCTAssertFalse(result == Reachability.Connection.connected)
    }
    
    func testStartNotifierYesInternet(){
        // Given
        let exp = expectation(description: "delegate called for connected")
        let expectedConnected = Reachability.Connection.connected
        
        let testDelegate = ReachibilityUtilsTestsDelegate(withExp: exp,
                                                          withExpectedConnected: expectedConnected)
        yesReachability?.delegate = testDelegate
        
        // When
        try? yesReachability?.startNotifier()
        waitForExpectations(timeout: TestUtil.waitTime)
    }
    
    func testStartNotifierNoInternet(){
        // Given
        let exp = expectation(description: "delegate called for not connected")
        let expectedNotConnected = Reachability.Connection.notConnected
        
        let testDelegate = ReachibilityUtilsTestsDelegate(withExp: exp,
                                                          withExpectedConnected: expectedNotConnected)
        noReachability?.delegate = testDelegate
        
        // When
        try? noReachability?.startNotifier()
        waitForExpectations(timeout: TestUtil.waitTime)
    }
}

// MARK: - ReachabilityDelegate
class ReachibilityUtilsTestsDelegate {
    let exp: XCTestExpectation
    var expedConnected: Reachability.Connection
    
    init(withExp exp: XCTestExpectation, withExpectedConnected expedConnected: Reachability.Connection) {
        self.exp = exp
        self.expedConnected = expedConnected
    }
}

// MARK: - ReachabilityDelegate
extension ReachibilityUtilsTestsDelegate: ReachabilityDelegate{
    func didChangeReachibility(status: Reachability.Connection) {
        // Then
        XCTAssertEqual(status, expedConnected)
        exp.fulfill()
    }
}
