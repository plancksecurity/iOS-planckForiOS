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
        guard let (mySelf: mySelfID, partner: partnerID, message: _) =
            TestUtil.setUpPepFromMail(
                emailFilePath: "HandshakeTests_mail_001.txt") else {
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
    }
}
