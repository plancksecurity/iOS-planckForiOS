//
//  HandshakePartnerTableViewCellViewModelTests.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 18.09.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import XCTest

@testable import MessageModel
@testable import pEpForiOS

class ImageProvider: IdentityImageProviderProtocol {
    var identitiesRequested = Set<Identity>()

    func image(forIdentity identity: Identity, callback: @escaping ImageReadyFunc) {
        identitiesRequested.insert(identity)
    }
}

class DecryptionDelegate: DecryptionAttemptCounterDelegate {
    var decryptedMessageDict: NSDictionary?

    override func decrypted(originalCdMessage: CdMessage, decryptedMessageDict: NSDictionary?,
                   rating: PEP_rating, keys: [String]) {
        super.decrypted(
            originalCdMessage: originalCdMessage, decryptedMessageDict: decryptedMessageDict,
            rating: rating, keys: keys)
        self.decryptedMessageDict = decryptedMessageDict
    }
}

class HandshakePartnerTableViewCellViewModelTests: XCTestCase {
    var persistentSetup: PersistentSetup!
    
    override func setUp() {
        super.setUp()

        XCTAssertTrue(PEPUtil.pEpClean())

        persistentSetup = PersistentSetup()
    }
    
    override func tearDown() {
        PEPSession.cleanup()
        persistentSetup = nil
        super.tearDown()
    }

    func importMail(session: PEPSession = PEPSession()) ->
        (message: Message, mySelfID: Identity, partnerID: Identity)? {
            let decryptDelegate = DecryptionDelegate()

            guard
                let (mySelf: mySelfID, partner: partnerID, message: message) =
                TestUtil.setUpPepFromMail(
                    emailFilePath: "HandshakeTests_mail_001.txt",
                    decryptDelegate: decryptDelegate) else {
                        XCTFail()
                        return nil
            }
            XCTAssertNotEqual(mySelfID.address, partnerID.address)

            let meIdent = mySelfID.pEpIdentity()
            let partnerIdent = partnerID.pEpIdentity()

            session.mySelf(meIdent)
            session.update(partnerIdent)

            XCTAssertNotNil(meIdent.fingerPrint)
            XCTAssertNotNil(partnerIdent.fingerPrint)
            XCTAssertFalse(partnerIdent.containsPGPCommType())

            XCTAssertEqual(partnerIdent.fingerPrint, "365AA0E985C912DAA867B1A77C6016EE84C971BF")

            return (message: message, mySelfID: mySelfID, partnerID: partnerID)
    }

    /**
     Tests trust/reset cycle without view model.
     */
    func testBasicTrustReset() {
        let session = PEPSession()

        guard
            let (message: _, mySelfID: _, partnerID: partnerID) = importMail(session: session) else
        {
            XCTFail()
            return
        }

        let partnerIdent = partnerID.pEpIdentity()
        session.update(partnerIdent)

        session.trustPersonalKey(partnerIdent)
        session.update(partnerIdent)
        XCTAssertFalse(partnerIdent.containsPGPCommType())

        session.keyResetTrust(partnerIdent)
        session.trustPersonalKey(partnerIdent)
        session.update(partnerIdent)
        XCTAssertFalse(partnerIdent.containsPGPCommType())
    }

    /**
     Tests trust/reset/mistrust/resut cycle without view model, using a backup
     to keep the comm type.
     */
    func testBasicTrustMistrustCycleUsingBackup() {
        let session = PEPSession()

        guard
            let (message: _, mySelfID: mySelfID,
                 partnerID: partnerID) = importMail(session: session) else {
                    XCTFail()
                    return
        }

        let meIdent = mySelfID.pEpIdentity()
        var partnerIdent = partnerID.pEpIdentity()
        session.mySelf(meIdent)
        session.update(partnerIdent)

        // back up the original
        let partnerIdentOrig = PEPIdentity(identity: partnerIdent)
        XCTAssertTrue(session.isPEPUser(partnerIdentOrig))

        session.trustPersonalKey(partnerIdent)
        session.update(partnerIdent)
        XCTAssertTrue(session.isPEPUser(partnerIdent))

        partnerIdent = PEPIdentity(identity: partnerIdentOrig) // restore backup
        session.keyResetTrust(partnerIdent)
        session.update(partnerIdent)
        XCTAssertTrue(session.isPEPUser(partnerIdent))

        partnerIdent = PEPIdentity(identity: partnerIdentOrig) // restore backup
        session.keyMistrusted(partnerIdent)
        session.update(partnerIdent)
        XCTAssertTrue(session.isPEPUser(partnerIdent))

        partnerIdent = PEPIdentity(identity: partnerIdentOrig) // restore backup
        session.keyResetTrust(partnerIdent)
        session.update(partnerIdent)
        XCTAssertTrue(session.isPEPUser(partnerIdent))

        partnerIdent = PEPIdentity(identity: partnerIdentOrig) // restore backup
        // The partner (restored from the backup) is still a pEp user
        XCTAssertTrue(session.isPEPUser(partnerIdent))
        session.trustPersonalKey(partnerIdent)
        session.update(partnerIdent)

        XCTAssertTrue(session.isPEPUser(partnerIdent))
    }

    /**
     Test trust/reset/mistrust cycle using view model.
     */
    func testViewModelTrustMistrustCycles() {
        let session = PEPSession()

        guard
            let (message: message, mySelfID: mySelfID,
                 partnerID: partnerID) = importMail(session: session) else {
                    XCTFail()
                    return
        }

        let imageProvider = ImageProvider()
        let vm = HandshakePartnerTableViewCellViewModel(
            message: message, ownIdentity: mySelfID, partner: partnerID, session: session,
            imageProvider: imageProvider)
        XCTAssertEqual(imageProvider.identitiesRequested.count, 1)
        XCTAssertEqual(imageProvider.identitiesRequested.first, partnerID)

        vm.confirmTrust()
        vm.resetTrust()

        vm.denyTrust()
        vm.resetTrust()

        vm.confirmTrust()
        vm.resetTrust()
    }
}
