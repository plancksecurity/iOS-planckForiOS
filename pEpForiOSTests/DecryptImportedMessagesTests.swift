//
//  DecryptImportedMessagesTests.swift
//  pEpForiOSTests
//
//  Created by Dirk Zimmermann on 08.01.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import XCTest

@testable import pEpForiOS
@testable import MessageModel

class DecryptImportedMessagesTests: XCTestCase {
    var persistentSetup: PersistentSetup!
    var session: PEPSession {
        return PEPSession()
    }
    var backgroundQueue: OperationQueue!

    // MARK: - setUp, tearDown

    override func setUp() {
        super.setUp()

        XCTAssertTrue(PEPUtil.pEpClean())

        persistentSetup = PersistentSetup()

        self.backgroundQueue = OperationQueue()
    }

    override func tearDown() {
        persistentSetup = nil
        backgroundQueue.cancelAllOperations()
        backgroundQueue = nil
        PEPSession.cleanup()
        super.tearDown()
    }

    // MARK: - Tests

    /**
     IOS-1300
     */
    func testDecrypt002() {
        let cdOwnAccount = DecryptionUtil.createLocalAccount(ownUserName: "Someonei",
                                                             ownUserID: "User_Someonei",
                                                             ownEmailAddress: "someone@gmx.de")
        self.backgroundQueue = OperationQueue()
        let cdMessage = DecryptionUtil.decryptTheMessage(
            testCase: self,
            backgroundQueue: backgroundQueue,
            cdOwnAccount: cdOwnAccount,
            fileName: "IOS-1300_odt_attachment.txt")

        guard let theCdMessage = cdMessage else {
            XCTFail()
            return
        }

        XCTAssertEqual(theCdMessage.pEpRating, Int16(PEP_rating_unencrypted.rawValue))
        XCTAssertEqual(theCdMessage.shortMessage, "needed")

        let attachments = theCdMessage.attachments?.array as? [CdAttachment] ?? []
        XCTAssertEqual(attachments.count, 1)

        let attachment1 = attachments[0]
        XCTAssertEqual(attachment1.mimeType, "application/vnd.oasis.opendocument.text")
        XCTAssertEqual(attachment1.fileName, "cid://253d226f-4e3a-b37f-4809-16cdc02f39e1@yahoo.com")
    }

    /**
     IOS-1364
     */
    func testDecryptUndisplayedAttachedJpegMessage() {
        let cdOwnAccount = DecryptionUtil.createLocalAccount(
            ownUserName: "ThisIsMe",
            ownUserID: "User_Me",
            ownEmailAddress: "iostest001@peptest.ch")

        self.backgroundQueue = OperationQueue()
        let cdMessage = DecryptionUtil.decryptTheMessage(
            testCase: self,
            backgroundQueue: backgroundQueue,
            cdOwnAccount: cdOwnAccount,
            fileName: "1364_Mail_missing_attached_image.txt")

        guard let theCdMessage = cdMessage else {
            XCTFail()
            return
        }

        XCTAssertEqual(theCdMessage.pEpRating, Int16(PEP_rating_unencrypted.rawValue))
        XCTAssertEqual(theCdMessage.shortMessage, "blah")
        XCTAssertEqual(theCdMessage.longMessage, "\n\n")

        let attachments = theCdMessage.attachments?.array as? [CdAttachment] ?? []
        XCTAssertEqual(attachments.count, 2)
        check(attachments: attachments as [MimeProtocol])

        guard let msg = theCdMessage.message() else {
            XCTFail()
            return
        }

        XCTAssertEqual(msg.attachments.count, 2)
        check(attachments: msg.attachments as [MimeProtocol])
    }

    /**
     IOS-1378
     - Note: If you need to manually verify something:
       * The public/secret key pair of Leon Kowalski (subject)
         is in `Leon Kowalski (19B9EE3B) – Private.asc`.
       * The public/secret key pair of Harry Bryant (sender) is in
         `Harry Bryant iostest002@peptest.ch (0x5716EA2D9AE32468) pub-sec.asc`.
     */
    func testSetOwnKey() {
        let cdOwnAccount = DecryptionUtil.createLocalAccount(
            ownUserName: "Rick Deckard",
            ownUserID: "rick_deckard_uid",
            ownEmailAddress: "iostest001@peptest.ch")

        try! TestUtil.importKeyByFileName(fileName: "Rick Deckard (EB50C250) – Private.asc")

        try! session.setOwnKey(cdOwnAccount.pEpIdentity(),
                               fingerprint: "456B937ED6D5806935F63CE5548738CCEB50C250")

        self.backgroundQueue = OperationQueue()
        let cdMessage = DecryptionUtil.decryptTheMessage(
            testCase: self,
            backgroundQueue: backgroundQueue,
            cdOwnAccount: cdOwnAccount,
            fileName: "SimplifiedKeyImport_Harry_To_Rick_with_Leon.txt")

        guard let theCdMessage = cdMessage else {
            XCTFail()
            return
        }

        // After ENGINE-465 is done, this should be PEP_rating_reliable
        XCTAssertEqual(theCdMessage.pEpRating, Int16(PEP_rating_unreliable.rawValue))

        XCTAssertEqual(theCdMessage.shortMessage, "Simplified Key Import")
        XCTAssertEqual(
            theCdMessage.longMessage,
            "iostest003@peptest.ch\nLeon Kowalski\n63FC29205A57EB3AEB780E846F239B0F19B9EE3B\n\nSee the key of Leon attached.\n")

        let attachments = theCdMessage.attachments?.array as? [CdAttachment] ?? []
        XCTAssertEqual(attachments.count, 0)

        guard let msg = theCdMessage.message() else {
            XCTFail()
            return
        }

        XCTAssertEqual(msg.attachments.count, 0)

        let leon = PEPIdentity(address: "iostest002@peptest.ch",
                               userID: PEP_OWN_USERID,
                               userName: "Leon Kowalski",
                               isOwn: true)
        try! session.update(leon)

        try! session.setOwnKey(leon, fingerprint: "63FC29205A57EB3AEB780E846F239B0F19B9EE3B")
    }

    // ENGINE-505
    /*
    func testNullInnerMimeType() {
        let cdOwnAccount = DecryptionUtil.createLocalAccount(
            ownUserName: "ThisIsMe",
            ownUserID: "User_Me",
            ownEmailAddress: "guile-user@gnu.org")

        self.backgroundQueue = OperationQueue()
        let cdMessage = DecryptionUtil.decryptTheMessage(
            testCase: self,
            backgroundQueue: backgroundQueue,
            cdOwnAccount: cdOwnAccount,
            fileName: "ENGINE-505_Mail_NullInnerMimeType.txt")

        guard let theCdMessage = cdMessage else {
            XCTFail()
            return
        }

        XCTAssertEqual(theCdMessage.pEpRating, Int16(PEP_rating_unencrypted.rawValue))
        XCTAssertEqual(theCdMessage.shortMessage,
                       "Re: Help needed debugging segfault with Guile 1.8.7")
        XCTAssertNil(theCdMessage.longMessage)

        let attachments = theCdMessage.attachments?.array as? [CdAttachment] ?? []
        XCTAssertEqual(attachments.count, 2)

        guard let msg = theCdMessage.message() else {
            XCTFail()
            return
        }

        XCTAssertEqual(msg.attachments.count, 1)
    }
     */

    // ENGINE-456 / IOS-1258
    /*
    func test_ENGINE_459() {
        let cdOwnAccount = DecryptionUtil.createLocalAccount(
            ownUserName: "ThisIsMe",
            ownUserID: "User_Me",
            ownEmailAddress: "iostest010@peptest.ch")

        self.backgroundQueue = OperationQueue()
        let cdMessage = DecryptionUtil.decryptTheMessage(
            testCase: self,
            backgroundQueue: backgroundQueue,
            cdOwnAccount: cdOwnAccount,
            fileName: "ENGINE-456_Mail_PEP_OUT_OF_MEMORY.txt")

        guard let theCdMessage = cdMessage else {
            XCTFail()
            return
        }

        XCTAssertEqual(theCdMessage.pEpRating, Int16(PEP_rating_unencrypted.rawValue))
        XCTAssertEqual(theCdMessage.shortMessage,
                       "Re: Help needed debugging segfault with Guile 1.8.7")
        XCTAssertNil(theCdMessage.longMessage)

        let attachments = theCdMessage.attachments?.array as? [CdAttachment] ?? []
        XCTAssertEqual(attachments.count, 2)

        guard let msg = theCdMessage.message() else {
            XCTFail()
            return
        }

        XCTAssertEqual(msg.attachments.count, 1)
    }
     */

    // MARK: - Helpers

    func check(attachments: [MimeProtocol]) {
        for i in 0..<attachments.count {
            let theAttachment = attachments[i]
            if i == 0 {
                XCTAssertEqual(theAttachment.mimeTypeFunc(), "image/jpeg")
            } else if i == 1 {
                XCTAssertEqual(theAttachment.mimeTypeFunc(), "text/plain")
                guard let theData = theAttachment.dataFunc(),
                    let dataString = String(data: theData, encoding: .utf8)  else {
                        XCTFail()
                        continue
                }
                XCTAssertEqual(dataString, "\n\nSent from my iPhone")
            }
        }
    }
}

// MARK: - Protocols

protocol MimeProtocol {
    func mimeTypeFunc() -> String?
    func dataFunc() -> Data?
}

extension Attachment: MimeProtocol {
    func mimeTypeFunc() -> String? {
        return mimeType
    }

    func dataFunc() -> Data? {
        return data
    }
}

extension CdAttachment: MimeProtocol {
    func mimeTypeFunc() -> String? {
        return mimeType
    }

    func dataFunc() -> Data? {
        return data
    }
}
