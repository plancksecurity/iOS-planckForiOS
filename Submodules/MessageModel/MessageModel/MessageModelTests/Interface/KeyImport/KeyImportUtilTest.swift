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
    /// 353E7B7239A9B7B0F8419CB3924B17115179C280 expires: 2023-01-15
    /// uid [unknown] test006@peptest.ch <test006@peptest.ch>
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
            try keyImport.setOwnKey(address: keyData.address, fingerprint: keyData.fingerprint)
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

        try keyImport.setOwnKey(address: keyData.address, fingerprint: keyData.fingerprint)
    }
}
