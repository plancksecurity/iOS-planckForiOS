//
//  PEPSessionTest.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 27/06/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import XCTest

import pEpForiOS
import MessageModel

class PEPSessionTest: XCTestCase {
    var persistentSetup: PersistentSetup!

    override func setUp() {
        super.setUp()
        persistentSetup = PersistentSetup()

    }
    override func tearDown() {
        persistentSetup = nil
        super.tearDown()
    }

    func testPEPConversion() {
        Log.info(component: "testPEPConversion", content: "test")
        let account = TestData().createWorkingAccount()
        account.save()

        let folder = Folder.create(name: "inbox", account: account, folderType: .inbox)
        folder.save()

        let uuid = MessageID.generate()
        let message = Message.create(uuid: uuid)
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
        let hf = HeaderField(name: "name", value: "Value")
        message.optionalFields = [hf]
        message.save( )
        let sesion = PEPSession()
        let cdmessage1 = CdMessage.first()!
        let cdmessage2 = cdmessage1
        let pepmessage = cdmessage1.pEpMessage()
        sesion.encryptMessageDict(pepmessage, extra: nil, dest: nil)
        sesion.decryptMessageDict(pepmessage, dest: nil, keys: nil)
        cdmessage2.update(pEpMessage: pepmessage)
        XCTAssertEqual(cdmessage2,cdmessage1)

        Log.verbose(component: "testPEPConversion", content: "test")
        Log.error(component: "testPEPConversion", errorString: "test")
    }

    func tryDecryptMessage(
        message: NSDictionary, myID: String, references: [String], session: PEPSession) {
        var pepDecryptedMessage: NSDictionary? = nil
        var keys: NSArray?
        let _ = session.decryptMessageDict(message as! PEPMessage,
                                           dest: &pepDecryptedMessage, keys: &keys)
        if let decMsg = pepDecryptedMessage {
            XCTAssertEqual(decMsg[kPepID] as? String, myID)
            XCTAssertEqual(decMsg[kPepReferences] as? [String] ?? [], references)
        } else {
            XCTFail()
        }
    }

    func testMessageIDAndReferencesAfterEncrypt() {
        let testData = TestData()
        let myself = testData.createWorkingIdentity(number: 0)
        let myID = "myID"
        let references = ["ref1", "ref2"]
        let dict = [
            kPepFrom: myself as AnyObject,
            kPepTo: NSArray(array: [myself]),
            kPepID: myID as AnyObject,
            kPepReferences: NSArray(array: references),
            kPepShortMessage: "Some Subject" as AnyObject,
            kPepLongMessage: "The text body" as AnyObject,
            kPepOutgoing: NSNumber(booleanLiteral: true)
        ] as PEPMessage

        let session = PEPSession()

        session.mySelf(NSMutableDictionary(dictionary: myself))

        let (status1, encMsg1) = session.encrypt(
            pEpMessageDict: dict, forIdentity: myself)
        XCTAssertEqual(status1, PEP_STATUS_OK)
        if let theEncMsg = encMsg1 {
            XCTAssertEqual(theEncMsg[kPepID] as? String, myID)
            XCTAssertEqual(theEncMsg[kPepReferences] as? [String] ?? [], references)
            tryDecryptMessage(
                message: theEncMsg, myID:myID, references: references, session: session)
        } else {
            XCTFail()
        }

        let (status2, encMsg2) = session.encrypt(
            pEpMessageDict: dict)
        XCTAssertEqual(status2, PEP_STATUS_OK)
        if let theEncMsg = encMsg2 {
            XCTAssertEqual(theEncMsg[kPepID] as? String, myID)
            XCTAssertEqual(theEncMsg[kPepReferences] as? [String] ?? [], references)
            tryDecryptMessage(
                message: theEncMsg, myID: myID, references: references, session: session)
        } else {
            XCTFail()
        }
    }

    func testParseMessageHeapBufferOverflow() {
        CWLogger.setLogger(Log.shared)
        let ps = PersistentSetup()
        ps.dummyToAvoidCompilerWarning()

        let cdAccount = TestData().createWorkingCdAccount()

        let folder = CdFolder.create()
        folder.account = cdAccount
        folder.name = ImapSync.defaultImapInboxName
        folder.uuid = MessageID.generate()

        guard let data = TestUtil.loadDataWithFileName("MessageHeapBufferOverflow.txt") else {
            XCTAssertTrue(false)
            return
        }
        let pantMessage = CWIMAPMessage(data: data)
        pantMessage.setFolder(CWIMAPFolder(name: ImapSync.defaultImapInboxName))
        guard let cdMessage = CdMessage.insertOrUpdate(
            pantomimeMessage: pantMessage, account: cdAccount, messageUpdate: CWMessageUpdate(),
            forceParseAttachments: true) else {
                XCTFail()
                return
        }

        for attch in (cdMessage.attachments?.array as? [CdAttachment] ?? []) {
            XCTAssertNotNil(attch.mimeType)
            XCTAssertNotNil(attch.data)
        }
    }

    func testDecryptMessageHeapBufferOverflow() {
        let ps = PersistentSetup()
        ps.dummyToAvoidCompilerWarning()

        let cdAccount = TestData().createWorkingCdAccount()

        let folder = CdFolder.create()
        folder.account = cdAccount
        folder.name = ImapSync.defaultImapInboxName
        folder.uuid = MessageID.generate()
        Record.saveAndWait()

        guard let data = TestUtil.loadDataWithFileName("MessageHeapBufferOverflow.txt") else {
            XCTAssertTrue(false)
            return
        }
        let pantMessage = CWIMAPMessage(data: data)
        pantMessage.setFolder(CWIMAPFolder(name: ImapSync.defaultImapInboxName))
        guard let cdMessage = CdMessage.insertOrUpdate(
            pantomimeMessage: pantMessage, account: cdAccount, messageUpdate: CWMessageUpdate(),
            forceParseAttachments: true) else {
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
}
