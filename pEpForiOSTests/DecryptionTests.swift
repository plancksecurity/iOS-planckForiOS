//
//  DecryptionTests.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 15.05.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import XCTest

@testable import pEpForiOS
import MessageModel

class DecryptionTests: XCTestCase {
    var cdOwnAccount: CdAccount!
    var pEpOwnIdentity: PEPIdentity!
    var cdSenderAccount: CdAccount!
    var pEpSenderIdentity: PEPIdentity!
    var cdInbox: CdFolder!

    var persistentSetup: PersistentSetup!
    var session: PEPSession {
        return PEPSession()
    }
    var backgroundQueue: OperationQueue!

    override func setUp() {
        super.setUp()
        
        XCTAssertTrue(PEPUtil.pEpClean())

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
        PEPSession.cleanup()
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

    func valueOf(header: String, inOptionalFields: [[String]]?) -> String? {
        for xs in inOptionalFields ?? [] {
            if xs.count > 1 && xs[0] == header {
                return xs[1]
            }
        }
        return nil
    }

    func testBasicDecryption(shouldEncrypt: Bool) {
        let msgShortMessage = "Subject 1"
        let msgLongMessage = "This is a message, for subject \(msgShortMessage)!"
        let messageID = "somemessageid"
        var pEpMsg = PEPMessage()
        pEpMsg[kPepFrom] = pEpSenderIdentity as AnyObject
        pEpMsg[kPepTo] = [pEpOwnIdentity] as NSArray
        pEpMsg[kPepLongMessage] = msgLongMessage as AnyObject
        pEpMsg[kPepOutgoing] = true as AnyObject
        pEpMsg[kPepID] = messageID as AnyObject

        var encryptedOrNotMailDict = PEPMessage()

        if shouldEncrypt {
            let (status, encryptedDictOpt) = session.encrypt(pEpMessageDict: pEpMsg)
            XCTAssertEqual(status, PEP_STATUS_OK)

            guard
                let theEncryptedDict = encryptedDictOpt as? PEPMessage,
                let theAttachments = theEncryptedDict[kPepAttachments] as? NSArray else {
                    XCTFail()
                    return
            }
            XCTAssertEqual(theAttachments.count, 2)
            XCTAssertNotNil(theEncryptedDict[kPepOptFields])
            guard let optFields = theEncryptedDict[kPepOptFields] as? NSArray else {
                XCTFail()
                return
            }
            XCTAssertTrue(optFields.count > 0)
            var pEpVersionFound = false
            for item in optFields {
                if let headerfield = item as? NSArray {
                    guard let name = headerfield[0] as? String else {
                        XCTFail()
                        continue
                    }
                    if name == kXpEpVersion {
                        pEpVersionFound = true
                    }
                    XCTAssertNotNil(headerfield[1] as? String)
                }
            }
            XCTAssertTrue(pEpVersionFound)

            XCTAssertNotEqual(theEncryptedDict[kPepID] as? String, messageID)
            XCTAssertNotEqual(theEncryptedDict[kPepShortMessage] as? String, msgShortMessage)
            XCTAssertNotEqual(theEncryptedDict[kPepLongMessage] as? String, msgLongMessage)

            encryptedOrNotMailDict = theEncryptedDict
        } else {
            encryptedOrNotMailDict = pEpMsg
        }

        guard let inboxName = cdInbox.name else {
            XCTFail()
            return
        }

        let pantMail = CWIMAPMessage(pEpMessage: encryptedOrNotMailDict, mailboxName: inboxName)
        pantMail.setUID(5) // some UID is needed to trigger decrypt

        if shouldEncrypt {
            XCTAssertTrue(pantMail.headerValue(forName: kXpEpVersion) is String)
        }

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
        if shouldEncrypt {
            XCTAssertTrue(cdMsg.isProbablyPGPMime())
        }

        Record.saveAndWait()

        XCTAssertEqual(Int32(cdMsg.pEpRating), Int32(PEPUtil.pEpRatingNone))

        let expectationDecryptHasRun = expectation(description: "expectationDecryptHasRun")
        let errorContainer = ErrorContainer()
        let decryptOp = DecryptMessagesOperation(parentName: #function,
                                                 errorContainer: errorContainer)
        decryptOp.completionBlock = {
            decryptOp.completionBlock = nil
            expectationDecryptHasRun.fulfill()
        }

        let decryptDelegate = DecryptionAttemptCounterDelegate()
        decryptOp.delegate = decryptDelegate

        backgroundQueue.addOperation(decryptOp)

        waitForExpectations(timeout: TestUtil.waitTime, handler: { error in
            XCTAssertNil(error)
        })

        XCTAssertEqual(decryptDelegate.numberOfMessageDecryptAttempts, 1)

        Record.Context.default.refreshAllObjects()
        if shouldEncrypt {
            XCTAssertGreaterThanOrEqual(Int32(cdMsg.pEpRating), PEP_rating_reliable.rawValue)
            XCTAssertEqual(cdMsg.shortMessage, msgShortMessage)
            XCTAssertEqual(cdMsg.longMessage, msgLongMessage)
        } else {
            XCTAssertEqual(Int32(cdMsg.pEpRating), Int32(PEP_rating_unencrypted.rawValue))
        }

        XCTAssertEqual(cdMsg.uuid, messageID)

        let pepDict = cdMsg.pEpMessage()
        let optFields = pepDict[kPepOptFields] as? [[String]]
        if shouldEncrypt {
            XCTAssertNotNil(pepDict[kPepOptFields])
            XCTAssertNotNil(optFields)
        }
        for header in [kXEncStatus, kXpEpVersion, kXKeylist] {
            let p = NSPredicate(format: "message = %@ and name = %@", cdMsg, header)
            let headerField = CdHeaderField.first(predicate: p)
            if shouldEncrypt {
                // check header in core data
                XCTAssertNotNil(headerField)
                // check header in dictionary derived from core data
                XCTAssertNotNil(valueOf(header: header, inOptionalFields: optFields))
            } else {
                // check header in core data
                XCTAssertNil(headerField)
                // check header in dictionary derived from core data
                XCTAssertNil(valueOf(header: header, inOptionalFields: optFields))
            }
        }
    }

    func testBasicDecryptionOfEncryptedMail() {
        testBasicDecryption(shouldEncrypt: true)
    }

    func testBasicDecryptionOfUnEncryptedMail() {
        testBasicDecryption(shouldEncrypt: false)
    }
}
