//
//  DecryptionUtil.swift
//  pEpForiOSTests
//
//  Created by Dirk Zimmermann on 03.10.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import Foundation
import XCTest
import CoreData

@testable import pEpForiOS
@testable import MessageModel

class DecryptionUtil {

    public static func decryptTheMessage(
        testCase: XCTestCase,
        backgroundQueue: OperationQueue,
        cdOwnAccount: CdAccount,
        fileName: String,
        checkCdMessage: ((CdMessage) -> ())? = nil) -> CdMessage? {
        guard let cdMessage = TestUtil.cdMessage(
            fileName: fileName,
            cdOwnAccount: cdOwnAccount) else {
                XCTFail()
                return nil
        }

        if let theChecker = checkCdMessage {
            theChecker(cdMessage)
        }

        let expDecrypted = testCase.expectation(description: "expDecrypted")
        let errorContainer = ErrorContainer()
        let decryptOperation = DecryptMessagesOperation(
            parentName: #function, errorContainer: errorContainer)
        decryptOperation.completionBlock = {
            decryptOperation.completionBlock = nil
            expDecrypted.fulfill()
        }
        let decryptDelegate = DecryptionAttemptCounterDelegate()
        decryptOperation.delegate = decryptDelegate
        backgroundQueue.addOperation(decryptOperation)

        testCase.waitForExpectations(timeout: TestUtil.waitTime) { error in
            XCTAssertNil(error)
        }

        XCTAssertEqual(decryptDelegate.numberOfMessageDecryptAttempts, 1)
        Stack.shared.mainContext.refreshAllObjects()

        guard
            let cdRecipients = cdMessage.to?.array as? [CdIdentity],
            cdRecipients.count == 1,
            let recipientIdentity = cdRecipients[0].identity()
            else {
                XCTFail()
                return cdMessage
        }
        XCTAssertTrue(recipientIdentity.isMySelf)

        guard let theSenderIdentity = cdMessage.from?.identity() else {
            XCTFail()
            return cdMessage
        }
        XCTAssertFalse(theSenderIdentity.isMySelf)

        return cdMessage
    }

    public static func createLocalAccount(ownUserName: String,
                                          ownUserID: String,
                                          ownEmailAddress: String,
                                          context: NSManagedObjectContext) -> CdAccount {
        let cdOwnAccount = SecretTestData().createWorkingCdAccount(number: 0, context: context)
        cdOwnAccount.identity?.userName = ownUserName
        cdOwnAccount.identity?.userID = ownUserID
        cdOwnAccount.identity?.address = ownEmailAddress

        let cdInbox = CdFolder(context: context)
        cdInbox.name = ImapSync.defaultImapInboxName
        cdInbox.account = cdOwnAccount
        context.saveAndLogErrors()

        return cdOwnAccount
    }
}
