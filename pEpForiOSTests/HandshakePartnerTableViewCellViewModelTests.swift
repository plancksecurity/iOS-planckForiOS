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
        persistentSetup = nil
        super.tearDown()
    }

    func importMail(session: PEPSession) ->
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

            let myDictMutable = mySelfID.pEpIdentity().mutableDictionary()
            let partnerMutable = partnerID.pEpIdentity().mutableDictionary()

            myDictMutable.update(session: session)
            partnerMutable.update(session: session)

            XCTAssertNotNil(myDictMutable[kPepFingerprint])
            XCTAssertNotNil(partnerMutable[kPepFingerprint])
            XCTAssertFalse(partnerMutable.containsPGPCommType)

            XCTAssertEqual(partnerMutable[kPepFingerprint] as? String,
                           "365AA0E985C912DAA867B1A77C6016EE84C971BF")

            return (message: message, mySelfID: mySelfID, partnerID: partnerID)
    }

    func testTrustAfterReset() {
        let session = PEPSessionCreator.shared.newSession()

        guard
            let (message: _, mySelfID: _, partnerID: partnerID) = importMail(session: session) else
        {
            XCTFail()
            return
        }

        let partnerMutable = partnerID.pEpIdentity().mutableDictionary()
        partnerMutable.update(session: session)

        session.trustPersonalKey(partnerMutable)
        partnerMutable.update(session: session)
        XCTAssertFalse(partnerMutable.containsPGPCommType)

        session.keyResetTrust(partnerMutable)
        session.trustPersonalKey(partnerMutable)
        partnerMutable.update(session: session)
        XCTAssertFalse(partnerMutable.containsPGPCommType)
    }

    func testPrimitiveTrustMistrustCycles() {
        let session = PEPSessionCreator.shared.newSession()

        guard
            let (message: _, mySelfID: mySelfID,
                 partnerID: partnerID) = importMail(session: session) else {
                    XCTFail()
                    return
        }

        let myDictMutable = mySelfID.pEpIdentity().mutableDictionary()
        var partnerMutable = partnerID.pEpIdentity().mutableDictionary()
        myDictMutable.update(session: session)
        partnerMutable.update(session: session)

        let partnerDictOrig = NSDictionary(dictionary: partnerMutable)

        XCTAssertFalse(partnerMutable.containsPGPCommType)

        partnerMutable = NSMutableDictionary(dictionary: partnerDictOrig)
        session.trustPersonalKey(partnerMutable)
        partnerMutable.update(session: session)
        XCTAssertFalse(partnerMutable.containsPGPCommType)

        partnerMutable = NSMutableDictionary(dictionary: partnerDictOrig)
        session.keyResetTrust(partnerMutable)
        partnerMutable.update(session: session)

        partnerMutable = NSMutableDictionary(dictionary: partnerDictOrig)
        session.keyMistrusted(partnerMutable)
        partnerMutable.update(session: session)
        XCTAssertFalse(partnerMutable.containsPGPCommType)

        partnerMutable = NSMutableDictionary(dictionary: partnerDictOrig)
        session.keyResetTrust(partnerMutable)
        partnerMutable.update(session: session)

        partnerMutable = NSMutableDictionary(dictionary: partnerDictOrig)
        session.trustPersonalKey(partnerMutable)
        partnerMutable.update(session: session)
    }

    func testTrustMistrustCycles() {
        let session = PEPSessionCreator.shared.newSession()

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
        XCTAssertFalse(vm.isPartnerPGPUser)

        vm.confirmTrust()
        XCTAssertFalse(vm.isPartnerPGPUser)
        vm.startStopTrusting()

        vm.denyTrust()
        vm.startStopTrusting()
        XCTAssertFalse(vm.isPartnerPGPUser)

        vm.confirmTrust()
        vm.startStopTrusting()
        XCTAssertFalse(vm.isPartnerPGPUser)
    }
}
