//
//  DecryptionTestsInternal.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 15.05.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import XCTest
import CoreData

@testable import pEpForiOS
@testable import MessageModel
import PantomimeFramework
import PEPObjCAdapterFramework

/**
 Tests internal encryption and decryption (that is, the test creates encrypted messages itself,
 and does not rely on outside data/services).
 */
class DecryptionTestsInternal: XCTestCase {
    var moc: NSManagedObjectContext!
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

        moc = Stack.shared.mainContext

        let cdMyAccount = SecretTestData().createWorkingCdAccount(number: 0, context: moc)
        guard let myPepIdentity = pEpIdentity(cdAccount: cdMyAccount) else {
            fatalError("Error PEPIdentity") //XCTFail() does can not be used here, sorry.
        }
        pEpOwnIdentity = myPepIdentity

        let cdSenderAccount = SecretTestData().createWorkingCdAccount(number: 1, context: moc)
        guard let senderPepIdentity = cdSenderAccount.identity?.pEpIdentity() else {
            fatalError("Error PEPIdentity") //XCTFail() does can not be used here, sorry.
        }
        self.cdOwnAccount = cdMyAccount
        self.cdSenderAccount = cdSenderAccount

        pEpSenderIdentity = senderPepIdentity
        try! session.mySelf(senderPepIdentity)

        cdInbox = CdFolder(context: moc)
        cdInbox.name = ImapSync.defaultImapInboxName
        cdInbox.account = cdMyAccount
        moc.saveAndLogErrors()

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
        guard let cdIdentity = cdAccount.identity, cdIdentity.isMySelf else {
                XCTFail("An account must have an identity that is mySelf.")
                return nil
        }
        let identity = cdIdentity.pEpIdentity()
        try! session.mySelf(identity)
        return identity
    }

    func valueOf(header: String, inOptionalFields: [[String]]?) -> String? {
        for xs in inOptionalFields ?? [] {
            if xs.count > 1 && xs[0] == header {
                return xs[1]
            }
        }
        return nil
    }

    func testBasicDecryption(shouldEncrypt: Bool, useSubject: Bool) {
        let msgShortMessage = "Subject 1"
        let msgLongMessage = "This is a message, for subject \(msgShortMessage)!"
        let messageID = "somemessageid"
        let references = ["ref1", "ref2", "ref3"]
        var pEpMsg = PEPMessageDict()
        pEpMsg[kPepFrom] = pEpSenderIdentity as AnyObject
        pEpMsg[kPepTo] = [pEpOwnIdentity] as NSArray
        pEpMsg[kPepLongMessage] = msgLongMessage as AnyObject
        if useSubject {
            pEpMsg[kPepShortMessage] = msgShortMessage as AnyObject
        }
        pEpMsg[kPepOutgoing] = true as AnyObject
        pEpMsg[kPepID] = messageID as AnyObject
        pEpMsg[kPepReferences] = references as AnyObject

        var encryptedOrNotMailDict = PEPMessageDict()

        if shouldEncrypt {
            do {
                let (_, encryptedDictOpt) = try session.encrypt(pEpMessageDict: pEpMsg)
                guard
                    let theEncryptedDict = encryptedDictOpt as? PEPMessageDict,
                    let theAttachments = theEncryptedDict[kPepAttachments] as? NSArray else {
                        XCTFail("No attachments")
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
                XCTAssertNotEqual(theEncryptedDict[kPepReferences] as? [String] ?? [], references)

                encryptedOrNotMailDict = theEncryptedDict
            } catch {
                XCTFail()
            }
        } else {
            encryptedOrNotMailDict = pEpMsg
        }

        guard let inboxName = cdInbox.name else {
            XCTFail()
            return
        }

        let pantMail = CWIMAPMessage(pEpMessageDict: encryptedOrNotMailDict, mailboxName: inboxName)
        pantMail.setUID(5) // some UID is needed to trigger decrypt

        if pEpSenderIdentity.userName == nil {
            XCTAssertNil(pantMail.from()?.personal())
        }

        if shouldEncrypt {
            XCTAssertTrue(pantMail.headerValue(forName: kXpEpVersion) is String)
        }

        guard
            let cdMsg = CdMessage.insertOrUpdate(pantomimeMessage: pantMail,
                                                 account: cdOwnAccount,
                                                 messageUpdate: CWMessageUpdate.newComplete(),
                                                 context: moc)
            else {
                    XCTFail()
                    return
        }

        cdMsg.parent = cdInbox

        XCTAssertFalse(cdMsg.imap?.localFlags?.flagDeleted ?? true)
        XCTAssertEqual(cdMsg.pEpRating, PEPUtil.pEpRatingNone)
        if shouldEncrypt {
            XCTAssertTrue(cdMsg.isProbablyPGPMime())
        }

        moc.saveAndLogErrors()

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

        moc.refreshAllObjects()
        if shouldEncrypt {
            XCTAssertGreaterThanOrEqual(cdMsg.pEpRating, Int16(PEPRating.reliable.rawValue))
            if useSubject {
                XCTAssertEqual(cdMsg.shortMessage, msgShortMessage)
            } else {
                XCTAssertTrue(cdMsg.shortMessage?.isEmpty ?? false)
            }
            XCTAssertEqual(cdMsg.longMessage, msgLongMessage)

            // check references (ENGINE-290)
            let cdRefs = (cdMsg.references?.array as? [CdMessageReference]) ?? []
            if cdRefs.count == references.count {
                for i in 0..<cdRefs.count {
                    XCTAssertEqual(cdRefs[i].reference, references[i])
                }
            } else {
                XCTFail()
            }
        } else {
            XCTAssertEqual(Int32(cdMsg.pEpRating), Int32(PEPRating.unencrypted.rawValue))
        }

        XCTAssertEqual(cdMsg.uuid, messageID)

        let pepDict = cdMsg.pEpMessageDict()
        let optFields = pepDict[kPepOptFields] as? [[String]]
        if shouldEncrypt {
            XCTAssertNotNil(pepDict[kPepOptFields])
            XCTAssertNotNil(optFields)
        }
        for header in [kXEncStatus, kXpEpVersion, kXKeylist] {
            let p = NSPredicate(format: "%K = %@ and %K = %@",
                                 CdHeaderField.RelationshipName.message, cdMsg,
                                 CdHeaderField.AttributeName.name, header)
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

    func testBasicDecryptionOfEncryptedMailWithSubject() {
        testBasicDecryption(shouldEncrypt: true, useSubject: true)
    }

    func testBasicDecryptionOfEncryptedMailWithoutSubject() {
        testBasicDecryption(shouldEncrypt: true, useSubject: false)
    }

    func testBasicDecryptionOfUnEncryptedMail() {
        testBasicDecryption(shouldEncrypt: false, useSubject: true)
    }

    func testBasicDecryptionOfUnEncryptedMailWithNilPersonal() {
        pEpSenderIdentity.userName = nil
        testBasicDecryption(shouldEncrypt: false, useSubject: true)
    }

    func testIncomingUnencryptedOutlookProbingMessage() {
        guard let _ = TestUtil.cdMessageAndSetUpPepFromMail(
            emailFilePath: "Microsoft_Outlook_Probing_Message_001.txt") else {
                XCTFail()
                return
        }
    }
}
