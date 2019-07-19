//
//  SetOwnKeyViewModelTests.swift
//  pEpForiOSTests
//
//  Created by Dirk Zimmermann on 03.10.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import XCTest
import CoreData

@testable import pEpForiOS
@testable import MessageModel //FIXME:
import PEPObjCAdapterFramework

class SetOwnKeyViewModelTests: CoreDataDrivenTestBase {
    var backgroundQueue: OperationQueue!

    /// Original own key.
    let ricksFingerprint = "456B937ED6D5806935F63CE5548738CCEB50C250"

    /// The fingerprint that will be part of the call to set_own_key.
    let leonsFingerprint = "63FC29205A57EB3AEB780E846F239B0F19B9EE3B"

    // MARK: - setUp, tearDown

    override func setUp() {
        super.setUp()

        XCTAssertTrue(PEPUtil.pEpClean())

        self.backgroundQueue = OperationQueue()
    }

    override func tearDown() {
        backgroundQueue.cancelAllOperations()
        backgroundQueue = nil
        super.tearDown()
    }

    // MARK: - Tests

    func testSetOwnKeyDirectly() {
        doTestSetOwnKey() {
            let leon = PEPIdentity(address: "iostest003@peptest.ch",
                                   userID: UUID().uuidString,
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

    /// Tries to trigger IOS-1674.
    func testTryToMakeSetOwnKeyCrash() {
        doTestSetOwnKey() {
            let leon = PEPIdentity(address: "iostest003@peptest.ch",
                                   userID: UUID().uuidString,
                                   userName: "Leon Kowalski",
                                   isOwn: true)

            do {
                try session.update(leon)
                XCTAssertNotNil(leon.fingerPrint)

                try session.keyMistrusted(leon)
                leon.fingerPrint = nil

                try session.setOwnKey(leon, fingerprint: leonsFingerprint)
            } catch {
                XCTFail("error: \(error)")
            }
        }
    }

    // MARK: - Helpers

    /// - Note: If you need to manually verify something:
    ///   * The public/secret key pair of Leon Kowalski (subject)
    ///     is in `Leon Kowalski (19B9EE3B) – Private.asc`.
    ///   * The public/secret key pair of Harry Bryant (sender) is in
    ///     `Harry Bryant iostest002@peptest.ch (0x5716EA2D9AE32468) pub-sec.asc`.
    private func doTestSetOwnKey(afterDecryption: () -> ()) {
        let cdOwnAccount1 = DecryptionUtil.createLocalAccount(
            ownUserName: "Rick Deckard",
            ownUserID: CdIdentity.pEpOwnUserID,
            ownEmailAddress: "iostest001@peptest.ch",
            context: moc)

        try! TestUtil.importKeyByFileName(fileName: "Rick Deckard (EB50C250) – Private.asc")

        try! session.setOwnKey(cdOwnAccount1.pEpIdentity(),
                               fingerprint: ricksFingerprint)

        let cdOwnAccount2 = DecryptionUtil.createLocalAccount(
            ownUserName: "Leon Kowalski",
            ownUserID: CdIdentity.pEpOwnUserID,
            ownEmailAddress: "iostest003@peptest.ch",
            context: moc)
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

        // After ENGINE-465 is done, this should be .reliable
        XCTAssertEqual(theCdMessage.pEpRating, Int16(PEPRating.unreliable.rawValue))

        XCTAssertEqual(theCdMessage.shortMessage, "Simplified Key Import")
        XCTAssertEqual(
            theCdMessage.longMessage,
            "iostest003@peptest.ch\nLeon Kowalski\n\(leonsFingerprint)\n\nSee the key of Leon attached.\n")

        let attachments = theCdMessage.attachments?.array as? [CdAttachment] ?? []
        XCTAssertEqual(attachments.count, 0)

        let msg = MessageModelObjectUtils.getMessage(fromCdMessage: theCdMessage)

        XCTAssertEqual(msg.attachments.count, 0)

        afterDecryption()
    }
}
