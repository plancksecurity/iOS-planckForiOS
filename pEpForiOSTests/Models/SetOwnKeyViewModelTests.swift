//
//  SetOwnKeyViewModelTests.swift
//  pEpForiOSTests
//
//  Created by Dirk Zimmermann on 03.10.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import XCTest

@testable import pEpForiOS
@testable import MessageModel

class SetOwnKeyViewModelTests: XCTestCase {
    var persistentSetup: PersistentSetup!
    var session: PEPSession {
        return PEPSession()
    }
    var backgroundQueue: OperationQueue!

    /**
     The fingerprint that will be part of the call to set_own_key.
     */
    let leonsFingerprint = "63FC29205A57EB3AEB780E846F239B0F19B9EE3B"

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

    func testSetOwnKeyDirectly() {
        doTestSetOwnKey() {
            let leon = PEPIdentity(address: "iostest003@peptest.ch",
                                   userID: PEP_OWN_USERID,
                                   userName: "Leon Kowalski",
                                   isOwn: true)
            try! session.update(leon)

            try! session.setOwnKey(leon, fingerprint: leonsFingerprint)
        }
    }

    func testSetOwnKeyViewModel() {
        doTestSetOwnKey() {
            let vm = SetOwnKeyViewModel()
            vm.email = "iostest003@peptest.ch"
            vm.fingerprint = leonsFingerprint
            vm.setOwnKey()
            XCTAssertEqual(vm.rawErrorString, nil)
        }
    }

    // MARK: - Helpers

    /**
     - Note: If you need to manually verify something:
     * The public/secret key pair of Leon Kowalski (subject)
     is in `Leon Kowalski (19B9EE3B) – Private.asc`.
     * The public/secret key pair of Harry Bryant (sender) is in
     `Harry Bryant iostest002@peptest.ch (0x5716EA2D9AE32468) pub-sec.asc`.
     */
    private func doTestSetOwnKey(afterDecryption: () -> ()) {
        let cdOwnAccount1 = DecryptionUtil.createLocalAccount(
            ownUserName: "Rick Deckard",
            ownUserID: "rick_deckard_uid",
            ownEmailAddress: "iostest001@peptest.ch")

        try! TestUtil.importKeyByFileName(fileName: "Rick Deckard (EB50C250) – Private.asc")

        try! session.setOwnKey(cdOwnAccount1.pEpIdentity(),
                               fingerprint: "456B937ED6D5806935F63CE5548738CCEB50C250")

        let cdOwnAccount2 = DecryptionUtil.createLocalAccount(
            ownUserName: "Leon Kowalski",
            ownUserID: "leon_kowalski_uid",
            ownEmailAddress: "iostest003@peptest.ch")
        let leonIdent = cdOwnAccount2.account().user
        let leonPepIdent = leonIdent.pEpIdentity()
        try! session.mySelf(leonPepIdent)
        XCTAssertNotNil(leonPepIdent)
        XCTAssertNotEqual(leonPepIdent.fingerPrint, leonsFingerprint)

        self.backgroundQueue = OperationQueue()
        let cdMessage = DecryptionUtil.decryptTheMessage(
            testCase: self,
            backgroundQueue: backgroundQueue,
            cdOwnAccount: cdOwnAccount1,
            fileName: "SimplifiedKeyImport_Harry_To_Rick_with_Leon.txt")

        guard let theCdMessage = cdMessage else {
            XCTFail()
            return
        }

        // After ENGINE-465 is done, this should be PEPRatingReliable
        XCTAssertEqual(theCdMessage.pEpRating, Int16(PEPRatingUnReliable.rawValue))

        XCTAssertEqual(theCdMessage.shortMessage, "Simplified Key Import")
        XCTAssertEqual(
            theCdMessage.longMessage,
            "iostest003@peptest.ch\nLeon Kowalski\n\(leonsFingerprint)\n\nSee the key of Leon attached.\n")

        let attachments = theCdMessage.attachments?.array as? [CdAttachment] ?? []
        XCTAssertEqual(attachments.count, 0)

        guard let msg = theCdMessage.message() else {
            XCTFail()
            return
        }

        XCTAssertEqual(msg.attachments.count, 0)

        afterDecryption()
    }
}
