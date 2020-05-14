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

        guard let url = testBundle.url(forResource: keyResourceName,
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

        guard let url = testBundle.url(forResource: keyResourceName,
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
