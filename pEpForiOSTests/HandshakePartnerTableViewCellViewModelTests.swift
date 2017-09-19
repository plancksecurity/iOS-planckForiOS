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
        persistentSetup = PersistentSetup()
    }
    
    override func tearDown() {
        persistentSetup = nil
        super.tearDown()
    }
    
    func testMailImport() {
        let decryptDelegate = DecryptionDelegate()

        guard
            let (mySelf: mySelfID, partner: partnerID, message: message) =
            TestUtil.setUpPepFromMail(
                emailFilePath: "HandshakeTests_mail_001.txt",
                decryptDelegate: decryptDelegate) else {
                    XCTFail()
                    return
        }
        XCTAssertNotEqual(mySelfID.address, partnerID.address)

        let myDictMutable = mySelfID.pEpIdentity().mutableDictionary()
        let partnerMutable = partnerID.pEpIdentity().mutableDictionary()

        let session = PEPSessionCreator.shared.newSession()
        myDictMutable.update(session: session)
        partnerMutable.update(session: session)

        XCTAssertNotNil(myDictMutable[kPepFingerprint])
        XCTAssertNotNil(partnerMutable[kPepFingerprint])
        XCTAssertFalse(partnerMutable.containsPGPCommType)

        XCTAssertEqual(partnerMutable[kPepFingerprint] as? String,
                       "365AA0E985C912DAA867B1A77C6016EE84C971BF")

        let imageProvider = ImageProvider()
        let vm = HandshakePartnerTableViewCellViewModel(
            message: message, ownIdentity: mySelfID, partner: partnerID, session: session,
            imageProvider: imageProvider)
        XCTAssertEqual(imageProvider.identitiesRequested.count, 1)
        XCTAssertEqual(imageProvider.identitiesRequested.first, partnerID)
        XCTAssertFalse(vm.isPartnerPGPUser)
    }
}
