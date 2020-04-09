//
//  QualifyServerIsLocalServiceTest.swift
//  pEpForiOSTests
//
//  Created by Dirk Zimmermann on 02.05.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import XCTest

import MessageModel

class QualifyServerIsLocalServiceTest: XCTestCase {

    func testServerQualification() {
        XCTAssertEqual(isLocalServer(serverName: "localhost"), true)
        XCTAssertEqual(isLocalServer(serverName: "peptest.ch"), false)
    }
}

// MARK: - HELPER

extension QualifyServerIsLocalServiceTest {

    private func isLocalServer(serverName: String) -> Bool? {
        let expQualified = expectation(description: "expQualified")
        let myDelegate = QualifyTestDelegate(expQualified: expQualified)
        let service = QualifyServerIsLocalService()
        service.delegate = myDelegate
        service.qualify(serverName: serverName)

        waitForExpectations(timeout: TestUtil.waitTime, handler: { error in
            XCTAssertNil(error)
            XCTAssertNil(myDelegate.error)
            XCTAssertEqual(myDelegate.serverName, serverName)
        })

        return myDelegate.isLocal
    }
}

class QualifyTestDelegate: QualifyServerIsLocalServiceDelegate {
    let expQualified: XCTestExpectation

    var serverName: String? = nil
    var isLocal: Bool? = nil
    var error: Error? = nil

    init(expQualified: XCTestExpectation) {
        self.expQualified = expQualified
    }

    func didQualify(serverName: String, isLocal: Bool?, error: Error?) {
        self.serverName = serverName
        self.isLocal = isLocal
        self.error = error
        expQualified.fulfill()
    }
}
