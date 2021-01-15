//
//  PEPSessionTest.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 27/06/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import XCTest
import CoreData

@testable import MessageModel
import PEPObjCAdapterFramework

class PEPSessionTest: PersistentStoreDrivenTestBase {

    // MARK: - Test

    func testPEPConversion() {
        let account = SecretTestData().createWorkingAccount(context: moc)
        account.save()

        let folder = Folder(name: "inbox", parent: nil, account: account, folderType: .inbox)
        folder.save()

        let uuid = UUID().uuidString
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
        guard let first = CdMessage.first(in: moc) else {
            XCTFail("No messages ...")
            return
        }
        //        let first = message.cdObject
        let cdmessage1 = first
        let cdmessage2 = cdmessage1
        let pEpMessage = cdmessage1.pEpMessage()

        let expEncryptDone = expectation(description: "expEnDeCryptDone")
        PEPAsyncSession().encryptMessage(pEpMessage, extraKeys: nil, encFormat: .PEP, errorCallback: { (_) in
            XCTFail()
            return
        }) { (src, dest) in
            expEncryptDone.fulfill()
        }
        waitForExpectations(timeout: TestUtil.waitTime)

        let expDecryptDone = expectation(description: "expDecryptDone")
        PEPAsyncSession().decryptMessage(pEpMessage, flags: .none, extraKeys: nil, errorCallback: { (_) in
            XCTFail()
            return
        }) { (_, _, _, _, _, _) in
            expDecryptDone.fulfill()
        }
        waitForExpectations(timeout: TestUtil.waitTime)
        
        let moc = cdmessage2.managedObjectContext!
        cdmessage2.update(pEpMessage: pEpMessage, context: moc)
        XCTAssertEqual(cdmessage2, cdmessage1)
    }

    func testParseMessageHeapBufferOverflow() {
        let cdAccount = SecretTestData().createWorkingCdAccount(context: moc)

        let folder = CdFolder(context: moc)
        folder.account = cdAccount
        folder.name = ImapConnection.defaultInboxName
        
        guard
            let cdMessage = TestUtil.cdMessage(testClass: type(of: self),
                                               fileName: "MessageHeapBufferOverflow.txt",
                                               cdOwnAccount: cdAccount)
            else {
                XCTFail()
                return
        }

        XCTAssertEqual(cdMessage.shortMessage, "test")

        for attch in (cdMessage.attachments?.array as? [CdAttachment] ?? []) {
            XCTAssertNotNil(attch.mimeType)
            XCTAssertNotNil(attch.data)
        }
    }

    // IOS-211
    func testAttachmentsDoNotGetDuplilcated() {
        let cdAccount = SecretTestData().createWorkingCdAccount(context: moc)

        let folder = CdFolder(context: moc)
        folder.account = cdAccount
        folder.name = ImapConnection.defaultInboxName

        guard
            let cdMessage = TestUtil.cdMessage(testClass:  type(of: self),
                                               fileName: "IOS-211-duplicated-attachments.txt",
                                               cdOwnAccount: cdAccount)
            else {
                XCTFail()
                return
        }

        let attachments = cdMessage.attachments?.array as? [CdAttachment] ?? []

        XCTAssertEqual(attachments.count, 1)
    }

    // MARK: - Helper

    func tryDecryptMessage(message: PEPMessage,
                           myID: String,
                           references: [String]) {
        var testee: PEPMessage? = nil

        let exp = expectation(description: "exp")
        PEPAsyncSession().decryptMessage(message, flags: .none, extraKeys: nil, errorCallback: { (error) in
            XCTFail(error.localizedDescription)
            exp.fulfill()
        }) { (_, pEpDecrypted, _, _, _, _) in
            testee = pEpDecrypted
            exp.fulfill()
        }
        waitForExpectations(timeout: TestUtil.waitTime)

        XCTAssertEqual(testee?.messageID, myID)
        // check that original references are restored (ENGINE-290)
        XCTAssertEqual(testee?.references ?? [], references)
    }
}
