//
//  XCTest+SyncAdapter.swift
//  MessageModelTests
//
//  Created by Andreas Buff on 21.07.20.
//  Copyright © 2020 pEp Security S.A. All rights reserved.
//

import XCTest
import PEPObjCAdapterFramework

// MARK: - XCTest+SyncAdapter

/// Wraps calls to adapter to avoid async behaviour.
/// All methods fail the test in case the adapter returns an error.
extension XCTestCase {
    func rating(for pEpIdentity: PEPIdentity) -> PEPRating{
        let exp = expectation(description: "exp")
        var pEpRating: PEPRating? = nil
        PEPSession().rating(for: pEpIdentity, errorCallback: { (_) in
            XCTFail()
            exp.fulfill()
        }) { (rating) in
            pEpRating = rating
            exp.fulfill()
        }
        waitForExpectations(timeout: TestUtil.waitTime)
        guard let rating = pEpRating else {
            XCTFail()
            return PEPRating.undefined
        }
        return rating
    }

    func mySelf(for pEpIdentity: PEPIdentity) -> PEPIdentity {
        let exp = expectation(description: "exp")
        var updatedPEPIdentity: PEPIdentity? = nil


        PEPSession().mySelf(pEpIdentity, errorCallback: { (_) in
            XCTFail()
            exp.fulfill()
        }) { (identity) in
            updatedPEPIdentity = identity
            exp.fulfill()
        }
        waitForExpectations(timeout: TestUtil.waitTime)
        guard let identity = updatedPEPIdentity else {
            XCTFail()
            return pEpIdentity
        }
        return identity
    }

    func languageList() -> [PEPLanguage] {
        var languages = [PEPLanguage]()

        let expHaveLanguages = expectation(description: "expHaveLanguages")
        PEPSession().languageList({ error in
            XCTFail()
            expHaveLanguages.fulfill()
        }) { langs in
            languages = langs
            expHaveLanguages.fulfill()
        }
        wait(for: [expHaveLanguages], timeout: TestUtil.waitTime)

        return languages
    }
}
