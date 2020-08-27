//
//  DecryptionTest.swift
//  MessageModelTests
//
//  Created by Dirk Zimmermann on 29.05.19.
//  Copyright © 2019 pEp Security S.A. All rights reserved.
//

import XCTest
@testable import MessageModel

import PEPObjCAdapterFramework

class DecryptionTest: PersistentStoreDrivenTestBase {
    /// See IOS-1432. The message itself is reliable, but at least one of its extra
    /// keys has an undefined rating, which the message inherits.
    func testLoadAndDecryptOutlookMessage() {
        guard let keyString = TestUtil.loadString(fileName: "IOS-1432_keypair.asc") else {
            XCTFail()
            return
        }

        let session = PEPSession()
        try! session.importKey(keyString)

        guard let cdIdent = cdAccount.identity else {
            XCTFail()
            return
        }
        let ident = MessageModelObjectUtils.getIdentity(fromCdIdentity: cdIdent)

        cdIdent.address = "test006@peptest.ch"
        cdIdent.userName = "Does Not Matter"
        cdIdent.userID = "own_id"

        try! session.setOwnKey(ident.pEpIdentity(),
                               fingerprint: "353E7B7239A9B7B0F8419CB3924B17115179C280")

        guard let cdMessage = TestUtil.cdMessage(
            testClass: DecryptionTest.self,
            fileName: "IOS-1432_message_from_outlook.txt",
            cdOwnAccount: cdAccount) else {
                XCTFail()
                return
        }

        let pEpMsg = cdMessage.pEpMessage()
        var rating: PEPRating = .undefined
        var extraKeys: [String]?

        let exp = expectation(description: "exp")
        PEPAsyncSession().decryptMessage(pEpMsg, flags: .none, extraKeys: extraKeys, errorCallback: { (error) in
            XCTFail(error.localizedDescription)
            exp.fulfill()
        }) { (_, _, keyList, pEpRating, _) in
            extraKeys = keyList
            rating = pEpRating
            exp.fulfill()
        }
        waitForExpectations(timeout: TestUtil.waitTime)

        XCTAssertEqual(rating.rawValue, PEPRating.undefined.rawValue)
        XCTAssertNotNil(extraKeys)
    }
}
