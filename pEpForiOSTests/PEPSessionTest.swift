//
//  PEPSessionTest.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 27/06/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import XCTest
import CoreData

@testable import pEpForiOS
@testable import MessageModel
import PEPObjCAdapterFramework

class PEPSessionTest: CoreDataDrivenTestBase {

    //MARK: - Test

    func testPEPConversion() {
        let account = SecretTestData().createWorkingAccount(context: moc)
        account.save()

        let folder = Folder(name: "inbox", parent: nil, account: account, folderType: .inbox)
        folder.save()

        let uuid = MessageID.generate()
        let message = Message(uuid: uuid, parentFolder: folder)
        message.shortMessage = "short message"
        message.longMessage = "long message"
        message.longMessageFormatted = "long message"
        message.from = account.user
        message.replaceTo(with: [account.user])
        message.replaceCc(with: [account.user])
        message.parent = folder
        message.sent = Date()
        message.save()
        let session = PEPSession()
        guard let first = CdMessage.first(in: moc) else {
            XCTFail("No messages ...")
            return
        }
//        let first = message.cdObject
        let cdmessage1 = first
        let cdmessage2 = cdmessage1
        let pEpMessage = cdmessage1.pEpMessage()

        try! session.encryptMessage(pEpMessage,
                                    extraKeys: nil,
                                    encFormat: .PEP,
                                    status: nil)
        try! session.decryptMessage(pEpMessage,
                                    flags: nil,
                                    rating: nil,
                                    extraKeys: nil,
                                    status: nil)
        let moc = cdmessage2.managedObjectContext! //!!!: not nice
        cdmessage2.update(pEpMessage: pEpMessage, context: moc)
        XCTAssertEqual(cdmessage2, cdmessage1)
    }

    func testMessageIDAndReferencesAfterEncrypt() {
        let testData = SecretTestData()
        let myself = testData.createWorkingIdentity(number: 0, context: moc)
        let mySubject = "Some Subject"
        let myMessageID = "myID"
        let references = ["ref1", "ref2", "ref3"]
        let pEpMessage = PEPMessage()

        pEpMessage.from = myself
        pEpMessage.to = [myself]
        pEpMessage.messageID = myMessageID
        pEpMessage.references = references
        pEpMessage.shortMessage = mySubject
        pEpMessage.longMessage = "The text body"
        pEpMessage.direction = .outgoing

        let session = PEPSession()

        try! session.mySelf(myself)

        let (_, encMsg1) = try! PEPUtils.encrypt(pEpMessage: pEpMessage, forSelf: myself)
        if let theEncMsg = encMsg1 {
            // expecting that sensitive data gets hidden (ENGINE-287)
            XCTAssertNotEqual(theEncMsg.messageID, myMessageID)
            XCTAssertNotEqual(theEncMsg.references ?? [], references)
            XCTAssertNotEqual(theEncMsg.shortMessage, mySubject)

            tryDecryptMessage(
                message: theEncMsg, myID:myMessageID, references: references, session: session)
        } else {
            XCTFail()
        }

        let (_, encMsg2) = try! PEPUtils.encrypt(pEpMessage: pEpMessage)
        if let theEncMsg = encMsg2 {
            // expecting that message ID gets hidden (ENGINE-288)
            XCTAssertNotEqual(theEncMsg.messageID, myMessageID)

            XCTAssertNotEqual(theEncMsg.references ?? [], references)
            XCTAssertNotEqual(theEncMsg.shortMessage, mySubject)
            tryDecryptMessage(
                message: theEncMsg, myID: myMessageID, references: references, session: session)
        } else {
            XCTFail()
        }
    }

    func testParseMessageHeapBufferOverflow() {
        let cdAccount = SecretTestData().createWorkingCdAccount(context: moc)

        let folder = CdFolder(context: moc)
        folder.account = cdAccount
        folder.name = ImapSync.defaultImapInboxName

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
        let cdAccount = SecretTestData().createWorkingCdAccount(context: moc)

        let folder = CdFolder(context: moc)
        folder.account = cdAccount
        folder.name = ImapSync.defaultImapInboxName
       moc.saveAndLogErrors()

        guard let cdMessage = TestUtil.cdMessage(
            fileName: "MessageHeapBufferOverflow.txt", cdOwnAccount: cdAccount) else {
                XCTFail()
                return
        }

        let pEpMessage = cdMessage.pEpMessageDict(outgoing: false)
        let session = PEPSession()
        var keys: NSArray?
        let pepDecryptedMessage = try! session.decryptMessageDict(
            pEpMessage.mutableDictionary(), flags: nil, rating: nil, extraKeys: &keys, status: nil)
        XCTAssertNotNil(pepDecryptedMessage[kPepLongMessage])
    }

    // IOS-211
    func testAttachmentsDoNotGetDuplilcated() {
        let cdAccount = SecretTestData().createWorkingCdAccount(context: moc)

        let folder = CdFolder(context: moc)
        folder.account = cdAccount
        folder.name = ImapSync.defaultImapInboxName

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
        message: PEPMessage, myID: String, references: [String],
        session: PEPSession = PEPSession()) {
        var keys: NSArray?
        let pepDecryptedMessage = try! session.decryptMessage(
            message, flags: nil, rating: nil, extraKeys: &keys, status: nil)
        XCTAssertEqual(pepDecryptedMessage.messageID, myID)
        // check that original references are restored (ENGINE-290)
        XCTAssertEqual(pepDecryptedMessage.references ?? [], references)
    }
}
