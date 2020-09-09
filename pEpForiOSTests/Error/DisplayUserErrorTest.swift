//
//  DisplayUserErrorTest.swift
//  pEpForiOSTests
//
//  Created by Andreas Buff on 30.11.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import XCTest

@testable import pEpForiOS
@testable import MessageModel

class DisplayUserErrorTest: XCTestCase {
    let smtpSentErrors: [SmtpSendError] = [.illegalState(#function),
                                           .authenticationFailed(#function, "unknown"),
                                           .connectionLost(#function, "Connection lost!"),
                                           .connectionTerminated(#function),
                                           .connectionTimedOut(#function, "Connection timed out!"),
                                           .badResponse(#function)]
    let imapSyncErrors: [ImapSyncOperationError] = [.illegalState(#function),
                                           .authenticationFailed(#function, "unknown"),
                                           .connectionLost(#function),
                                           .connectionTerminated(#function),
                                           .connectionTimedOut(#function),
                                           .folderAppendFailed,
                                           .badResponse(#function),
                                           .actionFailed]
    let backgroundGeneralErrors: [BackgroundError.GeneralError] =
        [.illegalState(info: "illegalState"),
         .invalidParameter(info: "invalidParameter"),
         .operationFailed(info: "operationFailed")]

    let backgroundImapErrors: [BackgroundError.ImapError] =
        [.invalidConnection(info: "invalidConnection")]

    let backgroundSmtpErrors: [BackgroundError.SmtpError] =
        [.invalidConnection(info: "invalidConnection"),
         .messageNotSent(info: "invalidConnection"),
         .transactionInitiationFailed(info: "transactionInitiationFailed"),
         .recipientIdentificationFailed(info: "recipientIdentificationFailed"),
         .transactionResetFailed(info: "transactionResetFailed"),
         .authenticationFailed(info: "authenticationFailed"),
         .connectionLost(info: "connectionLost"),
         .connectionTerminated(info: "connectionTerminated"),
         .connectionTimedOut(info: "connectionTimedOut"),
         .requestCancelled(info: "requestCancelled"),
         .badResponse(info: "badResponse")]

    let backgroundCoreDataErrors: [BackgroundError.CoreDataError] =
        [.couldNotInsertOrUpdate(info: "couldNotInsertOrUpdate"),
         .couldNotStoreMessage(info: "couldNotStoreMessage"),
         .couldNotFindAccount(info: "couldNotFindAccount"),
         .couldNotFindFolder(info: "couldNotFindFolder"),
         .couldNotFindMessage(info: "couldNotFindMessage")]

    let backgroundPepErrors: [BackgroundError.PepError] =
        [.passphraseRequired(info: "passphraseRequired"),
         .wrongPassphrase(info: "passphraseRequired")]

    func testSmtpSentErrors() {
        for error in smtpSentErrors {
            assert(error: error)
        }
    }

    func testImapSyncErrors() {
        for error in imapSyncErrors {
            assert(error: error)
        }
    }

    func testBackgroundGeneralErrors() {
        for error in backgroundGeneralErrors {
            assert(error: error)
        }
    }

    func testBackgroundImapErrors() {
        for error in backgroundImapErrors {
            assert(error: error)
        }
    }

    func testBackgroundSmtpErrors() {
        for error in backgroundSmtpErrors {
            assert(error: error)
        }
    }

    func testBackgroundCoreDataErrors() {
        for error in backgroundCoreDataErrors {
            assert(error: error)
        }
    }

    func testBackgroundPepErrors() {
        for error in backgroundPepErrors {
            assert(error: error)
        }
    }

    func testUnknownError() {
        class SomeError: Error {
            var localizedDescription = "localizedDescription"
        }
        let error = SomeError()
        assert(error: error, expectedDescription: error.localizedDescription)
    }

    // MARK: - HELPERS

    private func assert(error: Error, expectedDescription description: String? = nil) {
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
        if let expectedDescription = description {
            XCTAssertEqual(description, expectedDescription)
        }
    }
}
