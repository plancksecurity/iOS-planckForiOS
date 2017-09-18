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
    var session: PEPSession!
    var backgroundQueue: OperationQueue!

    override func setUp() {
        super.setUp()

        XCTAssertTrue(PEPUtil.pEpClean())
        session = PEPSessionCreator.shared.newSession()
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
        session = nil
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
        let msgLongMessage = "This is a message!"
        let msgShortMessage = "Subject1"
        var pEpMsg = PEPMessage()
        pEpMsg[kPepFrom] = pEpSenderIdentity as AnyObject
        pEpMsg[kPepTo] = [pEpOwnIdentity] as NSArray
        pEpMsg[kPepLongMessage] = "Subject: \(msgShortMessage)\n\(msgLongMessage)" as NSString
        pEpMsg[kPepOutgoing] = true as AnyObject

        var encryptedDict = PEPMessage()

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

            encryptedDict = theEncryptedDict
        }

        guard let inboxName = cdInbox.name else {
            XCTFail()
            return
        }

        let pantMail = CWIMAPMessage(pEpMessage: encryptedDict, mailboxName: inboxName)
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

        let expectationDecryptHasRun = expectation(description: "expectationDecryptHasRun")
        let errorContainer = ErrorContainer()
        let decryptOp = DecryptMessagesOperation(parentName: #function,
                                                 errorContainer: errorContainer)
        decryptOp.completionBlock = {
            decryptOp.completionBlock = nil
            expectationDecryptHasRun.fulfill()
        }
        backgroundQueue.addOperation(decryptOp)

        waitForExpectations(timeout: TestUtil.waitTime, handler: { error in
            XCTAssertNil(error)
        })

        XCTAssertEqual(decryptOp.numberOfMessagesDecrypted, 1)

        Record.Context.default.refreshAllObjects()
        if shouldEncrypt {
            XCTAssertGreaterThanOrEqual(Int32(cdMsg.pEpRating), PEP_rating_reliable.rawValue)
        } else {
            XCTAssertEqual(Int32(cdMsg.pEpRating), Int32(PEPUtil.pEpRatingNone))
        }
        if shouldEncrypt {
            XCTAssertEqual(cdMsg.shortMessage, msgShortMessage)
            XCTAssertEqual(cdMsg.longMessage, msgLongMessage)
        }

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
