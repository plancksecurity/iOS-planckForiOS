//
//  MessageModelTests.swift
//  MessageModelTests
//
//  Created by Dirk Zimmermann on 05/10/16.
//  Copyright © 2016 pEp Security S.A. All rights reserved.
//

import XCTest
import CoreData

import pEpIOSToolbox

@testable import MessageModel

class MessageModelTests: PersistentStoreDrivenTestBase {
    let jpegMimeType = "image/jpeg"
    var fixCdMessage: CdMessage!

    override func setUp() {
        super.setUp()
        fixCdMessage = TestUtil.createMessage(moc: Stack.shared.mainContext)
        moc.saveAndLogErrors()
    }

    func testFolderLookUp() {
        let acc = SecretTestData().createWorkingAccount()
        acc.session.commit()
        
        let f1 = Folder(name: "inbox", parent: nil, account: acc, folderType: .inbox)
        f1.session.commit()
        let f2 = Folder(name: "sent", parent: nil, account: acc, folderType: .sent)
        f2.session.commit()
        let f3 = Folder(name: "drafts", parent: nil, account: acc, folderType: .drafts)
        f3.session.commit()
        
        XCTAssertNotNil(Folder.by(account: acc, folderType: FolderType.inbox))
        XCTAssertNotNil(Folder.by(account: acc, folderType: FolderType.sent))
        XCTAssertNotNil(Folder.by(account: acc, folderType: FolderType.drafts))
    }

    func  testFolderLastLookedAt() {
        let acc = SecretTestData().createWorkingAccount()
        acc.session.commit()
        
        let f1 = Folder(name: "sent", parent: nil, account: acc, folderType: .sent)
        XCTAssertNil(f1.lastLookedAt)
        f1.updateLastLookAt()
        XCTAssertNotNil(f1.lastLookedAt)
        f1.session.commit()
        
        XCTAssertNotNil(Folder.by(account: acc, folderType: FolderType.sent)?.lastLookedAt)
    }

    func testExistingUserID() {
        let id = Identity(address: "whatever@example.com", userID: "userID1")
        id.session.commit()
        let id2 = Identity(address: "whatever@example.com", userID: "userID2")
        id2.session.commit()
        
        let cdIdent2 = CdIdentity.first(attribute: "address", value: id.address, in: moc)
        XCTAssertEqual(cdIdent2?.userID, id.userID)
    }

    func testExistingUserWithoutID(){
        let cdIdent = CdIdentity(context: moc)
        cdIdent.address = "whatever@example.com"
        let ident = Identity(address: cdIdent.address!, userID: "userID2")
        ident.session.commit()
        
        let idIdent2 = CdIdentity.first(attribute: "address", value: cdIdent.address!, in: moc)
        XCTAssertEqual(idIdent2?.userID, ident.userID)
    }

    func testAccountSave() {
        let account = SecretTestData().createWorkingAccount()
        account.session.commit()

        guard let cdAcc = CdAccount.by(address: account.user.address, context: moc) else {
            XCTFail()
            return
        }

        guard let cdId = cdAcc.identity else {
            XCTFail()
            return
        }

        XCTAssertTrue(cdId.isMySelf)

        guard let account2 = Account.by(address: account.user.address) else {
            XCTFail()
            return
        }

        XCTAssertTrue(account2.user.isMySelf)
    }

    func testCdAccountDelete() {
        guard let userAddress = cdAccount.identity?.address else {
            XCTFail()
            return
        }

        guard let account1 = Account.by(address: userAddress) else {
            XCTFail()
            return
        }

        account1.delete()
        account1.session.commit()

        XCTAssertNil(Account.by(address: userAddress))
    }

    func testExistingAccount() {
        let acc0 = SecretTestData().createWorkingAccount(number: 0)
        let acc1 = SecretTestData().createWorkingAccount(number: 0)
        
        acc0.session.commit()
        acc1.session.commit()
        
        if let acc2 = Account.by(address: acc0.user.address) {
            XCTAssertEqual(acc0.user, acc2.user)
        }
    }

    func testUpdateValueIdentity() {
        let id1 = Identity(address: "email@mail.com", userID: "userID", userName: "fakeusername")
        id1.session.commit()
        
        let id2 = Identity.by(address: id1.address)
        XCTAssertEqual(id1.userName, id2!.userName)
        XCTAssertEqual(id1, id2!)
    }
    
    func testAttachmentSearch() {
        let sameData = "Oh noes".data(using: .utf8)
        let nearlyIdentical1 = "Oh noes_1".data(using: .utf8)
        let nearlyIdentical2 = "Oh noes_2".data(using: .utf8)
        let uniqueData = "unique".data(using: .utf8)

        let attachments: [Attachment] = [
            // nearly identical
            Attachment(data: nearlyIdentical1,
                       mimeType: jpegMimeType,
                       fileName: "Attachment_000.jpg"),
            Attachment(data: nearlyIdentical2,
                       mimeType: jpegMimeType,
                       fileName: "Attachment_000.jpg"),

            // unique
            Attachment(
                data: uniqueData, mimeType: jpegMimeType, fileName: "Attachment_000.jpg"),

            // twins
            Attachment(data: sameData, mimeType: jpegMimeType, fileName: "Same_001.jpg"),
            Attachment(data: sameData, mimeType: jpegMimeType, fileName: "Same_001.jpg"),
            
            // cid-non-twins
            Attachment(data: sameData, mimeType: jpegMimeType, fileName: "Same_001.jpg"),
            Attachment(data: sameData, mimeType: jpegMimeType, fileName: "Same_001.jpg"),

            // mimeType-non-twins
            Attachment(data: sameData, mimeType: "image/mpeg",
                       fileName: "MimeTypeNonTwin_001.jpg"),
            Attachment(data: sameData, mimeType: jpegMimeType,
                       fileName: "MimeTypeNonTwin_001.jpg")
        ]
        for atch in attachments {
            fixCdMessage.addToAttachments(atch.cdObject)
        }
        fixCdMessage.managedObjectContext?.saveAndLogErrors() ?? Log.shared.errorAndCrash("No moc")

        let cdAttachments = CdAttachment.all(in: moc) as? [CdAttachment] ?? []
        XCTAssertEqual(cdAttachments.count, attachments.count)
    }
}
