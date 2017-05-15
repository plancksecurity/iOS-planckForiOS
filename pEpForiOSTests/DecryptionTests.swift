//
//  DecryptionTests.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 15.05.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import XCTest

import pEpForiOS
import MessageModel

class DecryptionTests: XCTestCase {
    var cdOwnAccount: CdAccount!
    var pEpOwnIdentity: PEPIdentity!
    var cdSenderAccount: CdAccount!
    var pEpSenderIdentity: PEPIdentity!
    var cdInbox: CdFolder!

    var persistentSetup: PersistentSetup!
    var session = PEPSession()
    var backgroundQueue: OperationQueue!

    override func setUp() {
        super.setUp()

        persistentSetup = PersistentSetup()

        let cdMyAccount = TestData().createWorkingCdAccount(number: 0)
        cdMyAccount.identity?.isMySelf = true
        let cdSenderAccount = TestData().createWorkingCdAccount(number: 1)
        cdSenderAccount.identity?.isMySelf = true

        cdInbox = CdFolder.create()
        cdInbox.name = ImapSync.defaultImapInboxName
        cdInbox.uuid = MessageID.generate()
        cdInbox.account = cdMyAccount

        TestUtil.skipValidation()
        Record.saveAndWait()

        self.cdOwnAccount = cdMyAccount
        self.cdSenderAccount = cdSenderAccount

        self.pEpOwnIdentity = pEpIdentity(cdAccount: cdMyAccount)
        self.pEpSenderIdentity = pEpIdentity(cdAccount: cdSenderAccount)

        self.backgroundQueue = OperationQueue()
    }

    override func tearDown() {
        persistentSetup = nil
        backgroundQueue.cancelAllOperations()
        backgroundQueue = nil
        super.tearDown()
    }

    func pEpIdentity(cdAccount: CdAccount) -> PEPIdentity? {
        guard
            let identityDict = cdAccount.identity?.pEpIdentity().mutableDictionary() else {
                XCTFail()
                return nil
        }
        session.mySelf(identityDict)
        guard let pEpId = identityDict as? PEPIdentity  else {
            XCTFail()
            return nil
        }
        return pEpId
    }

    func testBasicDecryption() {
        var pEpMsg = PEPMessage()
        pEpMsg[kPepFrom] = pEpSenderIdentity as AnyObject
        pEpMsg[kPepTo] = [pEpOwnIdentity] as NSArray
        pEpMsg[kPepLongMessage] = "Some text." as NSString
        pEpMsg[kPepOutgoing] = true as AnyObject

        let (status, encryptedDictOpt) = session.encrypt(pEpMessageDict: pEpMsg)
        XCTAssertEqual(status, PEP_STATUS_OK)

        guard
            let encryptedDict = encryptedDictOpt as? PEPMessage,
            let attachments = encryptedDict[kPepAttachments] as? NSArray else {
                XCTFail()
                return
        }
        XCTAssertEqual(attachments.count, 2)

        guard let inboxName = cdInbox.name else {
            XCTFail()
            return
        }

        let pantMail = PEPUtil.pantomime(pEpMessage: encryptedDict)
        pantMail.setFolder(CWFolder(name: inboxName))
        guard
            let cdMsg = CdMessage.insertOrUpdate(
                pantomimeMessage: pantMail, account: cdOwnAccount,
                messageUpdate: CWMessageUpdate.newComplete()) else {
                    XCTFail()
                    return
        }

        cdMsg.parent = cdInbox
        cdMsg.bodyFetched = true

        XCTAssertTrue(cdMsg.bodyFetched)
        XCTAssertFalse(cdMsg.imap?.localFlags?.flagDeleted ?? true)
        XCTAssertEqual(cdMsg.pEpRating, PEPUtil.pEpRatingNone)

        Record.saveAndWait()

        let expectationDecryptHasRun = expectation(description: "expectationDecryptHasRun")
        let errorContainer = ErrorContainer()
        let decryptOp = DecryptMessagesOperation(parentName: #function,
                                                 errorContainer: errorContainer)
        decryptOp.completionBlock = {
            expectationDecryptHasRun.fulfill()
        }
        backgroundQueue.addOperation(decryptOp)

        waitForExpectations(timeout: TestUtil.waitTime, handler: { error in
            XCTAssertNil(error)
        })

        XCTAssertEqual(decryptOp.numberOfMessagesDecrypted, 1)
    }
}
