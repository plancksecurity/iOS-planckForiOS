//
//  ReachabilityTests.swift
//  pEpForiOSTests
//
//  Created by Alejandro Gelos on 12/02/2019.
//  Copyright © 2019 p≡p Security S.A. All rights reserved.
//

import XCTest
@testable import pEpIOSToolbox

class ReachabilityTests: XCTestCase {
    
    private var yesReachability: Reachability?
    private var noReachability:  Reachability?
    private let yesInternetNetworkReachabilityMock = YesInternetReachabilityMock()
    private let noInternetLocalNetworkReachabilityMock = NoInternetReachabilityMock()
    
    override func setUp() {
        yesReachability = Reachability(networkReachability: yesInternetNetworkReachabilityMock)
        noReachability  = Reachability(networkReachability: noInternetLocalNetworkReachabilityMock)
    }
    
    override func tearDown() {
        yesReachability = nil
        noReachability  = nil
        super.tearDown()
    }
    
    func testInit() {
        // Given
        // When
        let reachability = Reachability()
        
        //Then
        XCTAssertNotNil(reachability)
    }
    
    func testGetConnectionStatusYesInternet() {
        // Given
        guard let yesReachability = yesReachability else {
            XCTFail()
            return
        }
        // When
        yesReachability.getConnectionStatus(
            completion: { result in
                // Then
                XCTAssertTrue(result == Reachability.Connection.connected)
        },
            failure: { error in
                XCTFail()
        })
    }
    
    func testGetConnectionStatusNoInternet() {
        guard let noReachability = noReachability else {
            XCTFail()
            return
        }
        // When
        noReachability.getConnectionStatus(
            completion: { result in
                // Then
                XCTAssertFalse(result == Reachability.Connection.connected)
        },
            failure: { error in
                XCTFail()
        })
    }
    
    func testStartNotifierYesInternet(){
        // Given
        guard let yesReachability = yesReachability else {
            XCTFail()
            return
        }
        let exp = expectation(description: "delegate called for connected")
        let expectedConnected = Reachability.Connection.connected
        let testDelegate = ReachabilityTestsDelegate(withExp: exp,
                                                          withExpectedConnected: expectedConnected)
        yesReachability.delegate = testDelegate
        
        // When
        yesReachability.startNotifier()
        
        // Then
        waitForExpectations(timeout: TestUtils.waitTimeLocal)
    }
    
    func testStartNotifierNoInternet(){
        // Given
        guard let noReachability = noReachability else {
            XCTFail()
            return
        }
        let exp = expectation(description: "delegate called for no connected")
        let expectedNotConnected = Reachability.Connection.notConnected
        let testDelegate = ReachabilityTestsDelegate(withExp: exp,
                                                          withExpectedConnected: expectedNotConnected)
        noReachability.delegate = testDelegate
        
        // When
        noReachability.startNotifier()
        
        // Then
        waitForExpectations(timeout: TestUtils.waitTimeLocal)
    }
}

// MARK: - ReachabilityDelegate
class ReachabilityTestsDelegate {
    let exp: XCTestExpectation
    var expedConnected: Reachability.Connection
    
    init(withExp exp: XCTestExpectation, withExpectedConnected expedConnected: Reachability.Connection) {
        self.exp = exp
        self.expedConnected = expedConnected
    }
}

// MARK: - ReachabilityDelegate
extension ReachabilityTestsDelegate: ReachabilityDelegate{
    func didFailToStartNotifier(error: Reachability.ReachabilityError) {
        XCTFail()
        exp.fulfill()
    }
    
    func didChangeReachability(status: Reachability.Connection) {
        // Then
        XCTAssertEqual(status, expedConnected)
        exp.fulfill()
    }
}
