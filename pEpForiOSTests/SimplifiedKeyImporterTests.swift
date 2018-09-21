//
//  SimplifiedKeyImporterTests.swift
//  pEpForiOSTests
//
//  Created by Dirk Zimmermann on 20.09.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import XCTest

@testable import pEpForiOS
@testable import MessageModel

class SimplifiedKeyImporterTests: XCTestCase {
    var persistentSetup: PersistentSetup!

    var ownAccount: Account!
    var inbox: Folder!

    var ownIdentity: Identity!
    var session: PEPSession!

    override func setUp() {
        super.setUp()

        session = PEPSession()

        XCTAssertTrue(PEPUtil.pEpClean())
        persistentSetup = PersistentSetup()

        let cdOwnAccount = SecretTestData().createWorkingCdAccount(number: 0)
        cdOwnAccount.identity?.userName = "iOS Test 002"
        cdOwnAccount.identity?.userID = "iostest002@peptest.ch_ID"
        cdOwnAccount.identity?.address = "iostest002@peptest.ch"

        let cdInbox = CdFolder.create()
        cdInbox.name = ImapSync.defaultImapInboxName
        cdInbox.uuid = MessageID.generate()
        cdInbox.account = cdOwnAccount

        Record.saveAndWait()

        ownAccount = cdOwnAccount.account()
        ownIdentity = cdOwnAccount.identity?.identity()
        inbox = cdInbox.folder()
    }

    override func tearDown() {
        persistentSetup = nil
    }

    func testBasics() {
        let myPepIdentity = ownIdentity.pEpIdentity()
        try! session.mySelf(myPepIdentity)

        guard let secretPublicKeyData = TestUtil.loadData(
            fileName: "8B691AD204E22FD1BF018E0D6C9EAD5A798018D1_pub_sec.txt") else {
                XCTFail()
                return
        }

        let msg = Message(uuid: "001", uid: 1, parentFolder: inbox)
        msg.shortMessage = "Some Subject"
        msg.longMessage = "Should contain a secret key"
        msg.from = ownIdentity
        msg.to = [ownIdentity]

        let secretPublicKeyAttachment = Attachment(
            data: secretPublicKeyData,
            mimeType: "application/pgp-keys",
            contentDisposition: .attachment)
        msg.attachments = [secretPublicKeyAttachment]

        let pEpMessage = PEPMessage(dictionary: msg.pEpMessageDict(outgoing: true))
        let (status, encryptedMessage) = try! session.encrypt(pEpMessage: pEpMessage)
        XCTAssertEqual(status, PEP_STATUS_OK)

        guard let theEncryptedMessage = encryptedMessage else {
            XCTFail()
            return
        }

        XCTAssertTrue(theEncryptedMessage.isLikelyPEPEncrypted())
    }
}
