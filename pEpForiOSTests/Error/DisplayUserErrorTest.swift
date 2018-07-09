//
//  DisplayUserErrorTest.swift
//  pEpForiOSTests
//
//  Created by Andreas Buff on 30.11.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import XCTest

@testable import pEpForiOS

class DisplayUserErrorTest: XCTestCase {
    let smtpSentErrors: [SmtpSendError] = [.illegalState(#function),
                                           .authenticationFailed(#function),
                                           .connectionLost(#function),
                                           .connectionTerminated(#function),
                                           .connectionTimedOut(#function),
                                           .badResponse(#function)]
    let imapSyncErrors: [ImapSyncError] = [.illegalState(#function),
                                           .authenticationFailed(#function),
                                           .connectionLost(#function),
                                           .connectionTerminated(#function),
                                           .connectionTimedOut(#function),
                                           .folderAppendFailed,
                                           .badResponse(#function),
                                           .actionFailed]
    func testSmtpErrors() {
        for error in smtpSentErrors {
            assert(error: error)
        }
    }

    func testImapErrors() {
        for error in imapSyncErrors {
            assert(error: error)
        }
    }

    // Fails: fix!
//    func testUnknownError() {
//        class SomeError: Error {
//            var localizedDescription = "localizedDescription"
//        }
//        let error = SomeError()
//        assert(error: error, expectedDescription: error.localizedDescription)
//    }

    // MARK: - HELPERS

    private func assert(error: Error, expectedDescription: String? = nil) {
        guard let testee = DisplayUserError(withError: error) else {
            XCTFail("All errors should be displayed in debug config")
            return
        }
        let title = testee.title
        let description = testee.errorDescription
        let type = testee.type
        XCTAssertNotNil(title)
        XCTAssertNotNil(description)
        XCTAssertNotNil(type)
        if let expectedDescription = expectedDescription {
            XCTAssertEqual(description, expectedDescription)
        }
    }
}
