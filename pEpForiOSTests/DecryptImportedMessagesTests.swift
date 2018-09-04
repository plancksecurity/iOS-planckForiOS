//
//  DecryptImportedMessagesTests.swift
//  pEpForiOSTests
//
//  Created by Dirk Zimmermann on 08.01.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import XCTest

@testable import pEpForiOS
@testable import MessageModel

class DecryptImportedMessagesTests: XCTestCase {
    var persistentSetup: PersistentSetup!
    var session: PEPSession {
        return PEPSession()
    }
    var backgroundQueue: OperationQueue!

    override func setUp() {
        super.setUp()

        XCTAssertTrue(PEPUtil.pEpClean())

        persistentSetup = PersistentSetup()

        self.backgroundQueue = OperationQueue()
    }

    override func tearDown() {
        persistentSetup = nil
        backgroundQueue.cancelAllOperations()
        backgroundQueue = nil
        PEPSession.cleanup()
        super.tearDown()
    }

    func createLocalAccount(ownUserName: String, ownUserID: String,
                            ownEmailAddress: String) -> CdAccount {
        let cdOwnAccount = SecretTestData().createWorkingCdAccount(number: 0)
        cdOwnAccount.identity?.userName = ownUserName
        cdOwnAccount.identity?.userID = ownUserID
        cdOwnAccount.identity?.address = ownEmailAddress

        let cdInbox = CdFolder.create()
        cdInbox.name = ImapSync.defaultImapInboxName
        cdInbox.uuid = MessageID.generate()
        cdInbox.account = cdOwnAccount
        Record.saveAndWait()

        return cdOwnAccount
    }

    func decryptTheMessage(cdOwnAccount: CdAccount, fileName: String) -> CdMessage? {
        guard let cdMessage = TestUtil.cdMessage(
            fileName: fileName,
            cdOwnAccount: cdOwnAccount) else {
                XCTFail()
                return nil
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

    func testDecrypt001() {
        let cdOwnAccount = createLocalAccount(ownUserName: "test002", ownUserID: "test002",
                                              ownEmailAddress: "iostest002@peptest.ch")

        // own keys
        try! TestUtil.importKeyByFileName(
            session, fileName: "IOS-884_001_iostest002@peptest.ch.pub.key")
        try! TestUtil.importKeyByFileName(
            session, fileName: "IOS-884_001_iostest002@peptest.ch.sec.key")

        // partner
        try! TestUtil.importKeyByFileName(
            session, fileName: "IOS-884_001_test010@peptest.ch.pub.key")

        self.backgroundQueue = OperationQueue()
        let cdMessage = decryptTheMessage(
            cdOwnAccount: cdOwnAccount, fileName: "IOS-884_001_Mail_from_P4A.txt")

        XCTAssertEqual(cdMessage?.pEpRating, Int16(PEP_rating_reliable.rawValue))
        XCTAssertEqual(cdMessage?.shortMessage, "Re:  ")
        XCTAssertTrue(cdMessage?.longMessage?.startsWith("It is yellow?") ?? false)
        XCTAssertEqual(cdMessage?.attachments?.count ?? 50, 0)
    }

    /**
     IOS-1300
     */
    func testDecrypt002() {
        let cdOwnAccount = createLocalAccount(ownUserName: "Someonei",
                                              ownUserID: "User_Someonei",
                                              ownEmailAddress: "someone@gmx.de")

        self.backgroundQueue = OperationQueue()
        let cdMessage = decryptTheMessage(
            cdOwnAccount: cdOwnAccount, fileName: "IOS-1300_odt_attachment.txt")

        guard let theCdMessage = cdMessage else {
            XCTFail()
            return
        }

        XCTAssertEqual(theCdMessage.pEpRating, Int16(PEP_rating_unencrypted.rawValue))
        XCTAssertEqual(theCdMessage.shortMessage, "needed")

        let attachments = theCdMessage.attachments?.array as? [CdAttachment] ?? []
        XCTAssertEqual(attachments.count, 1)

        let attachment1 = attachments[0]
        XCTAssertEqual(attachment1.mimeType, "application/vnd.oasis.opendocument.text")
        XCTAssertEqual(attachment1.fileName, "cid://253d226f-4e3a-b37f-4809-16cdc02f39e1@yahoo.com")
    }
}
