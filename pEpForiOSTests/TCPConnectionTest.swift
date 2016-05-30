//
//  TCPConnectionTest.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 27/05/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import XCTest

import pEpForiOS

class TCPConnectionTest: XCTestCase {
    let waitTime: NSTimeInterval = 10

    /**
     Test for verifying there are no retention cycles in CWTCPConnection
     */
    func testBasicConnection() {
        class ConnectionDelegate: CWConnectionDelegate {
            weak var connection: CWTCPConnection?
            var refCount: ReferenceCounter
            var expConnected: XCTestExpectation?
            var expReceivedEventRead: XCTestExpectation?
            var expReceivedEventWrite: XCTestExpectation?
            var expReceivedEventError: XCTestExpectation?

            init(connection: CWTCPConnection, refCount: ReferenceCounter) {
                self.connection = connection
                self.refCount = refCount
                self.refCount.inc()
            }

            @objc private func connectionEstablished() {
                expConnected?.fulfill()
            }

            @objc private func receivedEvent(
                theData: UnsafeMutablePointer<Void>, type theType: RunLoopEventType,
                extra theExtra: UnsafeMutablePointer<Void>, forMode theMode: String?) {
                switch theType {
                case .ET_RDESC:
                    let length = 1024
                    var buffer = [UInt8](count: length, repeatedValue: 0)
                    let count = connection?.read(&buffer, length: length)
                    let s = NSString(bytes: buffer, length: count!, encoding: NSUTF8StringEncoding)
                    print("read \(s)")
                    expReceivedEventRead?.fulfill()
                case .ET_WDESC:
                    expReceivedEventWrite?.fulfill()
                    print("can write")
                case .ET_EDESC:
                    expReceivedEventError?.fulfill()
                }
            }

            deinit {
                refCount.dec()
            }
        }
        let refCount = ReferenceCounter()
        for _ in 1...1 {
            let connectInfo = TestData.connectInfo
            var connection: CWTCPConnection? = CWTCPConnection.init(
                name: connectInfo.imapServerName, port: UInt32(connectInfo.imapServerPort),
                transport: connectInfo.imapTransport, background: true)
            let delegate = ConnectionDelegate.init(connection: connection!, refCount: refCount)
            delegate.expConnected = expectationWithDescription("connected")
            delegate.expReceivedEventRead = expectationWithDescription("read")
            delegate.expReceivedEventWrite = expectationWithDescription("write")
            connection?.delegate = delegate
            connection?.connect()
            waitForExpectationsWithTimeout(waitTime, handler: { error in
                XCTAssertNil(error)
                connection = nil
            })
        }
        XCTAssertEqual(refCount.refCount, 0)
    }
}