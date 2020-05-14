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
    override func setUpWithError() throws {
    }

    override func tearDownWithError() throws {
    }

    func testImportNonExistentKey() throws {
        do {
            let _ = try KeyImportUtil().importKey(url: URL(fileURLWithPath: "file:///ohno"))
            XCTFail()
        } catch KeyImportUtil.ImportError.cannotLoadKey {
            // expected
        } catch {
            XCTFail()
        }
    }

    func testSuccessfulImportButNoAccount() throws {
        let keyImport = KeyImportUtil()

        let testBundle = Bundle(for: KeyImportUtilTest.self)

        guard let url = testBundle.url(forResource: "IOS-1432_keypair.asc",
                                       withExtension: nil) else {
                                        XCTFail()
                                        return
        }

        let keyData = try keyImport.importKey(url: url)

        do {
            try keyImport.setOwnKey(keyData: keyData)
        } catch KeyImportUtil.SetOwnKeyError.noMatchingAccount {
            // expected
        }
    }

    func testSuccessfulImport() throws {
        let keyImport = KeyImportUtil()

        let testBundle = Bundle(for: KeyImportUtilTest.self)

        guard let url = testBundle.url(forResource: "IOS-1432_keypair.asc",
                                       withExtension: nil) else {
                                        XCTFail()
                                        return
        }

        let keyData = try keyImport.importKey(url: url)

        let ident = Identity(address: keyData.address,
                             userID: "some_user_id",
                             addressBookID: nil,
                             userName: "some name",
                             session: nil)

        let _ = Account(user: ident, servers: [])

        try keyImport.setOwnKey(keyData: keyData)
    }
}
