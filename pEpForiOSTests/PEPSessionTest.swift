//
//  PEPSessionTest.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 27/06/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import XCTest

@testable import pEpForiOS
import MessageModel

class PEPSessionTest: XCTestCase {
    var persistentSetup: PersistentSetup!

    // MARK: - Setup

    override func setUp() {
        super.setUp()
        XCTAssertTrue(PEPUtil.pEpClean())
        persistentSetup = PersistentSetup()

    }
    override func tearDown() {
        persistentSetup = nil
        PEPSession.cleanup()
        super.tearDown()
    }

    //MARK: - Test

    func testPEPConversion() {
        Log.info(component: "testPEPConversion", content: "test")
        let account = TestData().createWorkingAccount()
        account.save()

        let folder = Folder(name: "inbox", parent: nil, account: account, folderType: .inbox)
        folder.save()

        let uuid = MessageID.generate()
        let message = Message.fakeMessage(uuid: uuid)
        message.comments = "comment"
        message.shortMessage = "short message"
        message.longMessage = "long message"
        message.longMessageFormatted = "long message"
        message.from = account.user
        message.to = [account.user]
        message.cc = [account.user]
        message.bcc = [account.user]
        message.parent = folder
        message.sent = Date()
        message.received = Date()
        message.replyTo = [account.user]
        message.references = ["ref1"]
        message.save( )
        let session = PEPSession()
        guard let first = CdMessage.first() else {
            XCTFail("No messages ...")
            return
        }
        let cdmessage1 = first
        let cdmessage2 = cdmessage1
        let pepmessage = cdmessage1.pEpMessage()
        session.encryptMessageDict(pepmessage, extra: nil, dest: nil)
        session.decryptMessageDict(pepmessage, dest: nil, keys: nil)
        cdmessage2.update(pEpMessage: pepmessage)
        XCTAssertEqual(cdmessage2,cdmessage1)

        Log.verbose(component: "testPEPConversion", content: "test")
        Log.error(component: "testPEPConversion", errorString: "test")
    }

    func testMessageIDAndReferencesAfterEncrypt() {
        let testData = TestData()
        let myself = testData.createWorkingIdentity(number: 0)
        let mySubject = "Some Subject"
        let myID = "myID"
        let references = ["ref1", "ref2", "ref3"]
        let dict = [
            kPepFrom: myself as AnyObject,
            kPepTo: NSArray(array: [myself]),
            kPepID: myID as AnyObject,
            kPepReferences: NSArray(array: references),
            kPepShortMessage: mySubject as AnyObject,
            kPepLongMessage: "The text body" as AnyObject,
            kPepOutgoing: NSNumber(booleanLiteral: true)
        ] as PEPMessageDict

        let session = PEPSession()

        session.mySelf(NSMutableDictionary(dictionary: myself))

        let (status1, encMsg1) = session.encrypt(
            pEpMessageDict: dict, forIdentity: myself)
        XCTAssertEqual(status1, PEP_STATUS_OK)
        if let theEncMsg = encMsg1 {
            // expecting that sensitive data gets hidden (ENGINE-287)
            XCTAssertNotEqual(theEncMsg[kPepID] as? String, myID)
            XCTAssertNotEqual(theEncMsg[kPepReferences] as? [String] ?? [], references)
            XCTAssertNotEqual(theEncMsg[kPepShortMessage] as? String, mySubject)

            tryDecryptMessage(
                message: theEncMsg, myID:myID, references: references, session: session)
        } else {
            XCTFail()
        }

        let (status2, encMsg2) = session.encrypt(
            pEpMessageDict: dict)
        XCTAssertEqual(status2, PEP_STATUS_OK)
        if let theEncMsg = encMsg2 {
            // expecting that message ID gets hidden (ENGINE-288)
            XCTAssertNotEqual(theEncMsg[kPepID] as? String, myID)

            XCTAssertNotEqual(theEncMsg[kPepReferences] as? [String] ?? [], references)
            XCTAssertNotEqual(theEncMsg[kPepShortMessage] as? String, mySubject)
            tryDecryptMessage(
                message: theEncMsg, myID: myID, references: references, session: session)
        } else {
            XCTFail()
        }
    }

    func testParseMessageHeapBufferOverflow() {
        CWLogger.setLogger(Log.shared)

        let cdAccount = TestData().createWorkingCdAccount()

        let folder = CdFolder.create()
        folder.account = cdAccount
        folder.name = ImapSync.defaultImapInboxName
        folder.uuid = MessageID.generate()

        guard let cdMessage = TestUtil.cdMessage(
            fileName: "MessageHeapBufferOverflow.txt", cdOwnAccount: cdAccount) else {
                XCTFail()
                return
        }

        XCTAssertEqual(cdMessage.shortMessage, "test")

        for attch in (cdMessage.attachments?.array as? [CdAttachment] ?? []) {
            XCTAssertNotNil(attch.mimeType)
            XCTAssertNotNil(attch.data)
        }
    }

    func testDecryptMessageHeapBufferOverflow() {
        let cdAccount = TestData().createWorkingCdAccount()

        let folder = CdFolder.create()
        folder.account = cdAccount
        folder.name = ImapSync.defaultImapInboxName
        folder.uuid = MessageID.generate()
        Record.saveAndWait()

        guard let cdMessage = TestUtil.cdMessage(
            fileName: "MessageHeapBufferOverflow.txt", cdOwnAccount: cdAccount) else {
                XCTFail()
                return
        }

        let pEpMessage = cdMessage.pEpMessage(outgoing: false)
        let session = PEPSession()
        var pepDecryptedMessage: NSDictionary? = nil
        var keys: NSArray?
        let _ = session.decryptMessageDict(
            pEpMessage, dest: &pepDecryptedMessage, keys: &keys)
        XCTAssertNotNil(pepDecryptedMessage?[kPepLongMessage])
    }

    // IOS-211
    func testAttachmentsDoNotGetDuplilcated() {
        CWLogger.setLogger(Log.shared)

        let cdAccount = TestData().createWorkingCdAccount()

        let folder = CdFolder.create()
        folder.account = cdAccount
        folder.name = ImapSync.defaultImapInboxName
        folder.uuid = MessageID.generate()

        guard let cdMessage = TestUtil.cdMessage(
            fileName: "IOS-211-duplicated-attachments.txt", cdOwnAccount: cdAccount) else {
                XCTFail()
                return
        }

        let attachments = cdMessage.attachments?.array as? [CdAttachment] ?? []

        XCTAssertEqual(attachments.count, 1)
    }

    // MARK: - Helper

    func tryDecryptMessage(
        message: NSDictionary, myID: String, references: [String], session: PEPSession) {
        var pepDecryptedMessage: NSDictionary? = nil
        var keys: NSArray?
        let _ = session.decryptMessageDict(message as! PEPMessageDict,
                                           dest: &pepDecryptedMessage, keys: &keys)
        if let decMsg = pepDecryptedMessage {
            XCTAssertEqual(decMsg[kPepID] as? String, myID)
            // check that original references are restored (ENGINE-290)
            XCTAssertEqual(decMsg[kPepReferences] as? [String] ?? [], references)
        } else {
            XCTFail()
        }
    }
}
