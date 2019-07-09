//
//  CommunicationTypeTests.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 08.06.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import XCTest
import CoreData

@testable import pEpForiOS
@testable import MessageModel //FIXME:
import PEPObjCAdapterFramework

//!!!: uses a mix of Cd*Objects and MMObjects. Fix!
class MessageReevalutionTests: CoreDataDrivenTestBase {
    var pEpOwnIdentity: PEPIdentity!
    var cdSenderIdentity: CdIdentity!
    var pEpSenderIdentity: PEPIdentity!
    var cdInbox: CdFolder!
    var senderIdentity: Identity!
    var cdDecryptedMessage: CdMessage!

    var backgroundQueue: OperationQueue!

    override func setUp() {
        super.setUp()

        let ownIdentity = PEPIdentity(address: "iostest002@peptest.ch",
                                      userID: "iostest002@peptest.ch_ID",
                                      userName: "iOS Test 002",
                                      isOwn: true)

        // Account
        let cdMyAccount = SecretTestData().createWorkingCdAccount(number: 0, context: moc)
        cdMyAccount.identity?.userName = ownIdentity.userName
        cdMyAccount.identity?.userID = ownIdentity.userID
        cdMyAccount.identity?.address = ownIdentity.address

        // Inbox
        cdInbox = CdFolder(context: moc)
        cdInbox.name = ImapSync.defaultImapInboxName
        cdInbox.account = cdMyAccount
        self.cdAccount = cdMyAccount

        // Sender
        let senderUserName = "iOS Test 001"
        let senderUserID = "iostest001@peptest.ch_ID"
        let senderAddress = "iostest001@peptest.ch"
        let senderIdentityBuilder = Identity(address: senderAddress,
                                             userID: senderUserID,
                                             userName: senderUserName)
        senderIdentityBuilder.save()
        let moc = senderIdentityBuilder.moc
        guard let sender = CdIdentity.search(address: senderAddress, context: moc) else {
            XCTFail("Can't find")
            return
        }
        moc.saveAndLogErrors()
        self.cdSenderIdentity =  sender

        // sender pubkey
        try! TestUtil.importKeyByFileName(
            session, fileName: "CommunicationTypeTests_test001@peptest.ch_sec.asc")

        // own identity, fingerprint 2CAC9CE95910FBEDB539BDE49AB835A954F5BBF6
        try! TestUtil.importKeyByFileName(
            session, fileName: "CommunicationTypeTests_test002@peptest.ch_sec.asc")
        try! TestUtil.importKeyByFileName(
            session, fileName: "CommunicationTypeTests_test002@peptest.ch.asc")

        try! session.setOwnKey(ownIdentity,
                               fingerprint: "2CAC9CE95910FBEDB539BDE49AB835A954F5BBF6")

        self.backgroundQueue = OperationQueue()
        decryptTheMessage()
    }

    override func tearDown() {
        backgroundQueue?.cancelAllOperations() //!!!: serious issue. BackgroundQueue is randomly nil here. WTF?
        backgroundQueue = nil
        super.tearDown()
    }

    func decryptTheMessage() {
        guard let cdMessage = TestUtil.cdMessage(fileName: "CommunicationTypeTests_Message_test001_to_test002.txt",
                                                 cdOwnAccount: cdAccount)
            else {
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
        moc.refreshAllObjects()
        cdDecryptedMessage = cdMessage
        XCTAssertEqual(cdMessage.pEpRating, Int16(PEPRating.reliable.rawValue))
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
        XCTAssertFalse(try! senderIdent.isPEPUser(session).boolValue)
        XCTAssertEqual(senderIdentity.pEpRating(session: session), .reliable)

        try! session.keyMistrusted(senderIdent)

        let senderDict2 = senderIdentity.updatedIdentity(session: session)
        XCTAssertFalse(try! senderDict2.isPEPUser(session).boolValue)
        // ENGINE-343: At one point the rating was .Undefined.
        XCTAssertEqual(senderIdentity.pEpRating(), .haveNoKey)
    }

    func reevaluateMessage(expectedRating: PEPRating, inBackground: Bool = true,
                           infoMessage: String) {
        let message = MessageModelObjectUtils.getMessage(fromCdMessage: cdDecryptedMessage)

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

            moc.refreshAllObjects()
            XCTAssertEqual(cdDecryptedMessage.pEpRating, Int16(expectedRating.rawValue),
                           infoMessage)
        } else {
            let reevalOp = ReevaluateMessageRatingOperation(
                parentName: #function, message: message)
            reevalOp.reEvaluate()
        }
    }
    //!!!: Test crashes! IOS-1693"
//    func testTrustMistrust() {
//        let runReevaluationInBackground = false
//        let senderIdent = senderIdentity.updatedIdentity(session: session)
//
//        try! session.keyResetTrust(senderIdent)
//        XCTAssertFalse(senderIdent.isConfirmed)
//        reevaluateMessage(
//            expectedRating: .reliable,
//            inBackground: runReevaluationInBackground,
//            infoMessage: "in the beginning")
//
//        for _ in 0..<1 {
//            try! session.trustPersonalKey(senderIdent)
//            XCTAssertTrue(senderIdent.isConfirmed)
//            XCTAssertEqual(senderIdentity.pEpRating(session: session), .trusted)
//            reevaluateMessage(
//                expectedRating: .trusted,
//                inBackground: runReevaluationInBackground,
//                infoMessage: "after trust")
//
//            try! session.keyMistrusted(senderIdent)
//            XCTAssertEqual(senderIdentity.pEpRating(session: session), .haveNoKey)
//            reevaluateMessage(
//                expectedRating: .mistrust,
//                inBackground: runReevaluationInBackground,
//                infoMessage: "after mistrust")
//            try! session.update(senderIdent)
//            XCTAssertFalse(senderIdent.isConfirmed)
//        }
//    }
}
