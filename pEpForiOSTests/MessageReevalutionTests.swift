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
    var cdSenderAccount: CdAccount!
    var pEpSenderIdentity: PEPIdentity!
    var cdInbox: CdFolder!
    var senderIdentity: Identity!
    var cdDecryptedMessage: CdMessage!

    var persistentSetup: PersistentSetup!
    var session = PEPSession()
    var backgroundQueue: OperationQueue!

    override func setUp() {
        super.setUp()

        persistentSetup = PersistentSetup()

        let cdMyAccount = TestData().createWorkingCdAccount(number: 0)
        cdMyAccount.identity?.userName = "iOS Test 002"
        cdMyAccount.identity?.userID = "iostest002@peptest.ch_ID"
        cdMyAccount.identity?.address = "iostest002@peptest.ch"
        cdMyAccount.identity?.isMySelf = true

        let cdSenderAccount = TestData().createWorkingCdAccount(number: 1)
        cdSenderAccount.identity?.userName = "iOS Test 001"
        cdSenderAccount.identity?.userID = "iostest001@peptest.ch_ID"
        cdSenderAccount.identity?.address = "iostest001@peptest.ch"
        cdSenderAccount.identity?.isMySelf = false

        cdInbox = CdFolder.create()
        cdInbox.name = ImapSync.defaultImapInboxName
        cdInbox.uuid = MessageID.generate()
        cdInbox.account = cdMyAccount

        TestUtil.skipValidation()
        Record.saveAndWait()

        self.cdOwnAccount = cdMyAccount
        self.cdSenderAccount = cdSenderAccount

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
        super.tearDown()
    }

    func decryptTheMessage() {
        guard
            let msgTxt = TestUtil.loadData(
                fileName: "CommunicationTypeTests_Message_test001_to_test002.txt")
            else {
                XCTFail()
                return
        }
        let pantomimeMail = CWIMAPMessage(data: msgTxt, charset: "UTF-8")
        pantomimeMail.setFolder(CWIMAPFolder(name: ImapSync.defaultImapInboxName))
        guard let cdMessage = CdMessage.insertOrUpdate(
            pantomimeMessage: pantomimeMail, account: cdOwnAccount,
            messageUpdate: CWMessageUpdate(),
            forceParseAttachments: true) else {
                XCTFail()
                return
        }
        XCTAssertEqual(cdMessage.pEpRating, CdMessage.pEpRatingNone)
        XCTAssertEqual(cdMessage.shortMessage, "pEp")

        let expDecrypted = expectation(description: "expDecrypted")
        let errorContainer = ErrorContainer()
        let decryptOperation = DecryptMessagesOperation(
            parentName: #function, errorContainer: errorContainer)
        decryptOperation.completionBlock = {
            expDecrypted.fulfill()
        }
        backgroundQueue.addOperation(decryptOperation)

        waitForExpectations(timeout: TestUtil.waitTimeForever) { error in
            XCTAssertNil(error)
        }

        XCTAssertEqual(decryptOperation.numberOfMessagesDecrypted, 1)
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
        XCTAssertEqual(theSenderIdentity.address, cdSenderAccount.identity?.address)
        XCTAssertFalse(theSenderIdentity.isMySelf)

        senderIdentity = theSenderIdentity
    }

    func testCommunicationTypes() {
        let senderDict = senderIdentity.updatedIdentityDictionary(session: session)

        XCTAssertTrue(senderDict.isPGP)
        XCTAssertEqual(senderIdentity.pEpRating(), PEP_rating_reliable)

        session.keyMistrusted(senderDict)
        let senderDict2 = senderIdentity.updatedIdentityDictionary(session: session)
        XCTAssertFalse(senderDict2.isPGP) // mistrusting sets the comm type to PEP_ct_mistrusted
        XCTAssertEqual(senderIdentity.pEpRating(), PEP_rating_mistrust)

        session.keyResetTrust(senderDict2)
        let senderDict3 = senderIdentity.updatedIdentityDictionary(session: session)
        XCTAssertTrue(senderDict3.isPGP)
        XCTAssertEqual(senderIdentity.pEpRating(), PEP_rating_reliable)
    }

    func reevaluateMessage(expectedRating: PEP_rating, infoMessage: String) {
        guard let message = cdDecryptedMessage.message() else {
            XCTFail()
            return
        }
        let expReevaluated = expectation(description: "expReevaluated")
        let reevalOp = ReevaluateMessageRatingOperation(message: message)
        reevalOp.completionBlock = {
            expReevaluated.fulfill()
        }
        backgroundQueue.addOperation(reevalOp)
        waitForExpectations(timeout: TestUtil.waitTimeForever, handler: { error in
            XCTAssertNil(error)
        })

        Record.Context.default.refreshAllObjects()
        XCTAssertEqual(cdDecryptedMessage.pEpRating, Int16(expectedRating.rawValue), infoMessage)
    }

    func testTrustMistrust() {
        let senderDict = senderIdentity.updatedIdentityDictionary(session: session)
        session.keyResetTrust(senderDict)
        reevaluateMessage(expectedRating: PEP_rating_reliable, infoMessage: "in the beginning")

        for _ in 0..<1 {
            session.keyMistrusted(senderDict)
            XCTAssertEqual(senderIdentity.pEpRating(), PEP_rating_mistrust)
            reevaluateMessage(expectedRating: PEP_rating_mistrust, infoMessage: "after mistrust")
            let _ = senderDict.update(session: session)
            XCTAssertFalse(senderDict.isConfirmed)

            session.keyResetTrust(senderDict)
            XCTAssertEqual(senderIdentity.pEpRating(), PEP_rating_reliable)
            reevaluateMessage(expectedRating: PEP_rating_reliable, infoMessage: "after reset trust")

            session.trustPersonalKey(senderDict)
            XCTAssertEqual(senderIdentity.pEpRating(), PEP_rating_trusted)
            reevaluateMessage(expectedRating: PEP_rating_trusted, infoMessage: "after trust")
            let _ = senderDict.update(session: session)
            XCTAssertTrue(senderDict.isConfirmed)

            session.keyResetTrust(senderDict)
            XCTAssertEqual(senderIdentity.pEpRating(), PEP_rating_reliable)
            reevaluateMessage(expectedRating: PEP_rating_reliable, infoMessage: "after reset trust")
            let _ = senderDict.update(session: session)
            XCTAssertFalse(senderDict.isConfirmed)
        }
    }
}
