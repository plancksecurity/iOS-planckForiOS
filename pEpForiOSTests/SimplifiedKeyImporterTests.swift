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

    let fingerprint = "8B691AD204E22FD1BF018E0D6C9EAD5A798018D1"

    // MARK: - Setup, Teardown

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

    // MARK: - Tests

    func testNoImport() {
        runTest(messageDecorator: nil) { identities, _ in
            XCTAssertEqual(identities.count, 0)
        }

        let pEpIdent = ownIdentity.pEpIdentity() // without fingerprint

        let checkIdent1 = partialIdentityCopy(identity: pEpIdent)
        try! session.update(checkIdent1)
        XCTAssertNotEqual(checkIdent1.fingerPrint, fingerprint)

        let checkIdent2 = partialIdentityCopy(identity: pEpIdent)
        try! session.update(checkIdent2)
        XCTAssertNotEqual(checkIdent2.fingerPrint, fingerprint)
    }

    func testCorrectImport() {
        let decorator: (Message) -> () = { [weak self] message in
            guard let theSelf = self else {
                XCTFail()
                return
            }

            message.longMessage =
            "\(theSelf.ownIdentity.address)\n\(theSelf.fingerprint)"
        }

        runTest(messageDecorator: decorator) { [weak self] identities, originalFingerprint in
            guard let theSelf = self else {
                XCTFail()
                return
            }

            XCTAssertEqual(identities.count, 1)

            guard let theIdent = identities.first else {
                return
            }

            XCTAssertEqual(theIdent.address, theSelf.ownIdentity.address)
            XCTAssertEqual(theIdent.fingerPrint, theSelf.fingerprint)

            let checkIdent1 = theSelf.partialIdentityCopy(identity: theIdent)
            try! theSelf.session.update(checkIdent1)
            XCTAssertEqual(checkIdent1.fingerPrint, theSelf.fingerprint)
            XCTAssertNotEqual(checkIdent1.fingerPrint, originalFingerprint)

            let checkIdent2 = theSelf.partialIdentityCopy(identity: theIdent)
            try! theSelf.session.mySelf(checkIdent2)
            XCTAssertEqual(checkIdent2.fingerPrint, theSelf.fingerprint)
            XCTAssertNotEqual(checkIdent2.fingerPrint, originalFingerprint)
        }
    }

    // MARK: - Helpers

    func partialIdentityCopy(identity: PEPIdentity) -> PEPIdentity {
        return PEPIdentity(address: identity.address,
                           userID: identity.userID,
                           userName: identity.userName,
                           isOwn: identity.isOwn)
    }

    func runTest(messageDecorator: ((Message) -> ())?,
                 verifier: (([PEPIdentity], String) -> ())?) {
        let myPepIdentity = ownIdentity.pEpIdentity()
        try! session.mySelf(myPepIdentity)

        guard let originalFingerprint = myPepIdentity.fingerPrint else {
            XCTFail()
            return
        }

        guard let importFingerprint = myPepIdentity.fingerPrint else {
            XCTFail()
            return
        }

        guard let secretPublicKeyString = TestUtil.loadString(
            fileName: "8B691AD204E22FD1BF018E0D6C9EAD5A798018D1_pub_sec.txt") else {
                XCTFail()
                return
        }

        // The engine should do this for attached keys automatically on decryption,
        // so let's fake it.
        try! session.importKey(secretPublicKeyString)

        let msg = Message(uuid: "001", uid: 1, parentFolder: inbox)
        msg.shortMessage = "Some Subject"
        msg.longMessage = "Should contain a secret key"
        msg.from = ownIdentity
        msg.to = [ownIdentity]

        if let decorator = messageDecorator {
            decorator(msg)
        }

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
            theVerifier(identities, originalFingerprint)
        }
    }
}
