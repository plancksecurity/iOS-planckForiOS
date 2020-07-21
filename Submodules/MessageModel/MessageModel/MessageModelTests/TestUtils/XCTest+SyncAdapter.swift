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
        PEPAsyncSession().rating(for: pEpIdentity, errorCallback: { (_) in
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
}
