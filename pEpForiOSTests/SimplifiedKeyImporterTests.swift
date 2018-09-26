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

    func testNoImport() {
        runTest(messageDecorator: nil) { identities in
            XCTAssertEqual(identities.count, 0)
        }
    }

    // MARK: - Helpers

    func runTest(messageDecorator: ((Message) -> ())?,
                 verifier: (([PEPIdentity]) -> ())?) {
        let myPepIdentity = ownIdentity.pEpIdentity()
        try! session.mySelf(myPepIdentity)

        guard let importFingerprint = myPepIdentity.fingerPrint else {
            XCTFail()
            return
        }

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

        if let decorator = messageDecorator {
            decorator(msg)
        }

        let secretPublicKeyAttachment = Attachment(
            data: secretPublicKeyData,
            mimeType: MimeTypeUtil.defaultMimeType,
            contentDisposition: .attachment)
        msg.attachments = [secretPublicKeyAttachment]

        let pEpMessage = PEPMessage(dictionary: msg.pEpMessageDict(outgoing: true))
        let (encryptionStatus, encryptedMessage) = try! session.encrypt(pEpMessage: pEpMessage)
        XCTAssertEqual(encryptionStatus, PEP_STATUS_OK)

        guard let theEncryptedMessage = encryptedMessage else {
            XCTFail()
            return
        }

        XCTAssertTrue(theEncryptedMessage.isLikelyPEPEncrypted())

        var flags = PEP_decrypt_flag_none
        var rating = PEP_rating_b0rken
        var extraKeys: NSArray?
        var decryptionStatus = PEP_SYNC_NO_TRUST
        let decryptedMessage = try! session.decryptMessage(
            theEncryptedMessage,
            flags: &flags,
            rating: &rating,
            extraKeys: &extraKeys,
            status: &decryptionStatus)

        guard let theExtraKeys = extraKeys else {
            XCTFail()
            return
        }

        XCTAssertEqual((decryptedMessage.attachments ?? []).count, msg.attachments.count)
        XCTAssertFalse(decryptedMessage.isLikelyPEPEncrypted())

        let importer = SimplifiedKeyImporter(trustedFingerPrint: importFingerprint)
        let identities = importer.process(message: decryptedMessage, keys: theExtraKeys)

        if let theVerifier = verifier {
            theVerifier(identities)
        }
    }
}
