//
//  CommunicationTypeTests.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 08.06.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import XCTest

@testable import pEpForiOS
@testable import MessageModel

class MessageReevalutionTests: XCTestCase {
    var cdOwnAccount: CdAccount!
    var pEpOwnIdentity: PEPIdentity!
    var cdSenderIdentity: CdIdentity!
    var pEpSenderIdentity: PEPIdentity!
    var cdInbox: CdFolder!
    var senderIdentity: Identity!
    var cdDecryptedMessage: CdMessage!

    var persistentSetup: PersistentSetup!
    var session: PEPSession {
        return PEPSession()
    }
    var backgroundQueue: OperationQueue!

    override func setUp() {
        super.setUp()

        XCTAssertTrue(PEPUtil.pEpClean())

        persistentSetup = PersistentSetup()

        // Account
        let cdMyAccount = SecretTestData().createWorkingCdAccount(number: 0)
        cdMyAccount.identity?.userName = "iOS Test 002"
        cdMyAccount.identity?.userID = "iostest002@peptest.ch_ID"
        cdMyAccount.identity?.address = "iostest002@peptest.ch"

        // Inbox
        cdInbox = CdFolder.create()
        cdInbox.name = ImapSync.defaultImapInboxName
        cdInbox.uuid = MessageID.generate()
        cdInbox.account = cdMyAccount
        TestUtil.skipValidation()
        self.cdOwnAccount = cdMyAccount

        // Sender
        let senderUserName = "iOS Test 001"
        let senderUserID = "iostest001@peptest.ch_ID"
        let senderAddress = "iostest001@peptest.ch"
        let senderIdentityBuilder = Identity.create(address: senderAddress,
                                                    userID: senderUserID,
                                                    userName: senderUserName,
                                                    isMySelf: false)
        senderIdentityBuilder.save()
        guard let sender = CdIdentity.search(address: senderAddress) else {
            Log.shared.errorAndCrash(component: #function, errorString: "Cant find ")
            return
        }
        Record.saveAndWait()
        self.cdSenderIdentity =  sender

        // Test Keys
        TestUtil.importKeyByFileName(
            session, fileName: "CommunicationTypeTests_test001@peptest.ch_sec.asc")
        TestUtil.importKeyByFileName(
            session, fileName: "CommunicationTypeTests_test001@peptest.ch.asc")

        TestUtil.importKeyByFileName(
            session, fileName: "CommunicationTypeTests_test002@peptest.ch_sec.asc")
        TestUtil.importKeyByFileName(
            session, fileName: "CommunicationTypeTests_test002@peptest.ch.asc")

        self.backgroundQueue = OperationQueue()
        decryptTheMessage()
    }

    override func tearDown() {
        persistentSetup = nil
        backgroundQueue.cancelAllOperations()
        backgroundQueue = nil
        PEPSession.cleanup()
        super.tearDown()
    }

    func decryptTheMessage() {
        guard let cdMessage = TestUtil.cdMessage(
            fileName: "CommunicationTypeTests_Message_test001_to_test002.txt",
            cdOwnAccount: cdOwnAccount) else {
                XCTFail()
                return
        }

        let expDecrypted = expectation(description: "expDecrypted")
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

        waitForExpectations(timeout: TestUtil.waitTime) { error in
            XCTAssertNil(error)
        }

        XCTAssertEqual(decryptDelegate.numberOfMessageDecryptAttempts, 1)
        Record.Context.main.refreshAllObjects()
        cdDecryptedMessage = cdMessage
        XCTAssertEqual(cdMessage.pEpRating, Int16(PEP_rating_reliable.rawValue))
        XCTAssertEqual(cdMessage.shortMessage, "oh yeah, subject")
        XCTAssertTrue(cdMessage.longMessage?.startsWith("Some text body!") ?? false)

        guard
            let cdRecipients = cdMessage.to?.array as? [CdIdentity],
            cdRecipients.count == 1,
            let recipientIdentity = cdRecipients[0].identity()
            else {
                XCTFail()
                return
        }
        XCTAssertTrue(recipientIdentity.isMySelf)

        guard let theSenderIdentity = cdMessage.from?.identity() else {
            XCTFail()
            return
        }
        XCTAssertEqual(theSenderIdentity.address, cdSenderIdentity.address)
        XCTAssertFalse(theSenderIdentity.isMySelf)

        senderIdentity = theSenderIdentity
    }

    func testCommunicationTypes() {
        let senderIdent = senderIdentity.updatedIdentity(session: session)
        XCTAssertFalse(senderIdent.isPEPUser(session))
        XCTAssertEqual(senderIdentity.pEpRating(session: session), PEP_rating_reliable)

        try! session.keyMistrusted(senderIdent)

        let senderDict2 = senderIdentity.updatedIdentity(session: session)
        XCTAssertFalse(senderDict2.isPEPUser(session))
        // ENGINE-343: At one point the rating was PEP_rating_undefined.
        XCTAssertEqual(senderIdentity.pEpRating(), PEP_rating_have_no_key)
    }

    func reevaluateMessage(expectedRating: PEP_rating, inBackground: Bool = true,
                           infoMessage: String) {
        guard let message = cdDecryptedMessage.message() else {
            XCTFail()
            return
        }
        if inBackground {
            let expReevaluated = expectation(description: "expReevaluated")
            let reevalOp = ReevaluateMessageRatingOperation(parentName: #function, message: message)
            reevalOp.completionBlock = {
                reevalOp.completionBlock = nil
                expReevaluated.fulfill()
            }
            backgroundQueue.addOperation(reevalOp)
            waitForExpectations(timeout: TestUtil.waitTime, handler: { error in
                XCTAssertNil(error)
            })

            Record.Context.default.refreshAllObjects()
            XCTAssertEqual(cdDecryptedMessage.pEpRating, Int16(expectedRating.rawValue),
                           infoMessage)
        } else {
            let reevalOp = ReevaluateMessageRatingOperation(
                parentName: #function, message: message)
            reevalOp.reEvaluate(context: Record.Context.default)
        }
    }

    func testTrustMistrust() {
        let runReevaluationInBackground = false
        let senderIdent = senderIdentity.updatedIdentity(session: session)

        session.keyResetTrust(senderIdent)
        XCTAssertFalse(senderIdent.isConfirmed)
        reevaluateMessage(
            expectedRating: PEP_rating_reliable,
            inBackground: runReevaluationInBackground,
            infoMessage: "in the beginning")

        for _ in 0..<1 {
            try! session.trustPersonalKey(senderIdent)
            XCTAssertTrue(senderIdent.isConfirmed)
            XCTAssertEqual(senderIdentity.pEpRating(session: session), PEP_rating_trusted)
            reevaluateMessage(
                expectedRating: PEP_rating_trusted,
                inBackground: runReevaluationInBackground,
                infoMessage: "after trust")

            let senderIdentCopy = PEPIdentity(identity: senderIdent)
            try! session.keyMistrusted(senderIdent)
            XCTAssertEqual(senderIdentity.pEpRating(session: session), PEP_rating_have_no_key)
            reevaluateMessage(
                expectedRating: PEP_rating_mistrust,
                inBackground: runReevaluationInBackground,
                infoMessage: "after mistrust")
            try! session.update(senderIdent)
            XCTAssertFalse(senderIdent.isConfirmed)

            session.keyResetTrust(senderIdentCopy)
            XCTAssertEqual(senderIdentity.pEpRating(session: session), PEP_rating_have_no_key)
            reevaluateMessage(
                expectedRating: PEP_rating_reliable,
                inBackground: runReevaluationInBackground,
                infoMessage: "after reset trust")
        }
    }
}
