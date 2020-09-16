//
//  KeyImportUtilTest.swift
//  MessageModelTests
//
//  Created by Dirk Zimmermann on 14.05.20.
//  Copyright © 2020 pEp Security S.A. All rights reserved.
//

import XCTest

import MessageModel

class KeyImportUtilTest: XCTestCase {
    /// A key pair that can be imported. Gets loaded from the test bundle.
    let keyResourceName = "IOS-1432_keypair.asc"

    func testImportNonExistentKey() throws {
        let expImport = expectation(description: "expImort")
        KeyImportUtil().importKey(url: URL(fileURLWithPath: "file:///ohno"),
                                  errorCallback: { error in
                                    if let theError = error as? KeyImportUtil.ImportError {
                                        switch theError {
                                        case .cannotLoadKey: // expected
                                            break
                                        default:
                                            XCTFail()
                                        }
                                    }
                                    expImport.fulfill()
        }) { keyData in
            XCTFail()
            expImport.fulfill()
        }
        wait(for: [expImport], timeout: TestUtil.waitTime)
    }

    func testSuccessfulImportButNoAccount() throws {
        let testBundle = Bundle(for: KeyImportUtilTest.self)

        guard let url = testBundle.url(forResource: keyResourceName,
                                       withExtension: nil) else {
                                        XCTFail()
                                        return
        }

        let expImport = expectation(description: "expImort")
        var someKeyDatas = [KeyImportUtil.KeyData]()
        KeyImportUtil().importKey(url: url,
                                  errorCallback: { error in
                                    XCTFail()
                                    expImport.fulfill()
        }) { keyDatas in
            someKeyDatas = keyDatas
            expImport.fulfill()
        }
        wait(for: [expImport], timeout: TestUtil.waitTime)

        XCTAssertFalse(someKeyDatas.isEmpty)

        guard let theKeyData = someKeyDatas[safe: 0] else {
            XCTFail()
            return
        }

        let expSetOwnKey = expectation(description: "expSetOwnKey")
        KeyImportUtil().setOwnKey(userName: theKeyData.userName,
                                  address: theKeyData.address,
                                  fingerprint: theKeyData.fingerprint,
                                  errorCallback: { error in
                                    if let theError = error as? KeyImportUtil.SetOwnKeyError {
                                        switch theError {
                                        case .noMatchingAccount: // expected
                                            break
                                        default:
                                            XCTFail()
                                        }
                                    }
                                    expSetOwnKey.fulfill()
        }) {
            expSetOwnKey.fulfill()
        }
        wait(for: [expSetOwnKey], timeout: TestUtil.waitTime)
    }

    func testSuccessfulImport() throws {
        let keyImport = KeyImportUtil()

        let testBundle = Bundle(for: KeyImportUtilTest.self)

        guard let url = testBundle.url(forResource: keyResourceName,
                                       withExtension: nil) else {
                                        XCTFail()
                                        return
        }

        var someKeyDatas = [KeyImportUtil.KeyData]()

        let expImport = expectation(description: "expImort")
        keyImport.importKey(url: url,
                            errorCallback: { error in
                                XCTFail()
                                expImport.fulfill()
        }) { keyDatas in
            someKeyDatas = keyDatas
            expImport.fulfill()
        }
        wait(for: [expImport], timeout: TestUtil.waitTime)

        XCTAssertFalse(someKeyDatas.isEmpty)

        guard let theKeyData = someKeyDatas[safe: 0] else {
            XCTFail()
            return
        }

        let ident = Identity(address: theKeyData.address,
                             userID: "some_user_id",
                             addressBookID: nil,
                             userName: "some name",
                             session: nil)

        let _ = Account(user: ident, servers: [])
        Session.main.commit()

        let expSetOwnKey = expectation(description: "expSetOwnKey")
        keyImport.setOwnKey(userName: theKeyData.userName,
                            address: theKeyData.address,
                            fingerprint: theKeyData.fingerprint,
                            errorCallback: { error in
                                XCTFail()
                                expSetOwnKey.fulfill()
        }) {
            expSetOwnKey.fulfill()
        }
        wait(for: [expSetOwnKey], timeout: TestUtil.waitTime)
    }
}
