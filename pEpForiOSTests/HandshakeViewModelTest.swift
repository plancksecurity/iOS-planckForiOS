//
//  HandshakeViewModel.swift
//  pEpForiOSTests
//
//  Created by Martin Brude on 31/01/2020.
//  Copyright © 2020 p≡p Security S.A. All rights reserved.
//

import XCTest
import CoreData
@testable import MessageModel
@testable import pEpForiOS


class HandshakeViewModelTest: CoreDataDrivenTestBase {

    var handshakeViewModel : HandshakeViewModel?
    let numberOfRowsToGenerate = 1
    var identities = [Identity]()
    
    override func setUp() {
        super.setUp()
        
        for index in 0..<numberOfRowsToGenerate {
            let identity = SecretTestData().createWorkingCdIdentity(number: index,
                                                                    isMyself: false,
                                                                    context: moc)
            let id = Identity(cdObject: identity, context: moc)
            identities.append(id)
        }

        moc.saveAndLogErrors()
    }

    override func tearDown() {
        super.tearDown()
    }

    func testNumberOfRows() {
        setupViewModel()
        guard let numberOfRows = handshakeViewModel?.rows.count else {
            XCTFail("The handshakeViewModel can't be nil")
            return
        }
        XCTAssertEqual(numberOfRows, numberOfRowsToGenerate)
    }

    //
    func testHandleRejectHandshakePressed() {
        setupViewModel()
        let firstItemPosition = IndexPath(item: 0, section: 0)
        handshakeViewModel?.handshakeUtil = HandShakeUtilMock()
        handshakeViewModel?.handleRejectHandshakePressed(at: firstItemPosition)

        guard let _ = handshakeViewModel?.rows else {
            XCTFail("The handshakeViewModel can't be nil")
            return
        }
        
        guard let firstRow = handshakeViewModel?.rows[0] else {
            XCTFail("The first row must exist")
            return
        }

        XCTAssertEqual("", firstRow.privacyStatus)
    }
    
    //
    func testHandleConfirmHandshakePressed() {
//        setupViewModel()
//        let firstItemPosition = IndexPath(item: 0, section: 0)
//        handshakeViewModel?.handleConfirmHandshakePressed(at: firstItemPosition)
//
//        guard let rows = handshakeViewModel?.rows else {
//            XCTFail()
//            return
//        }
//
//        XCTAssertEqual("", rows[0].privacyStatus)
    }
    
    //
    func testHandleResetPressed() {
//        setupViewModel()
//        let firstItemPosition = IndexPath(item: 0, section: 0)
//        handshakeViewModel?.handleResetPressed(at: firstItemPosition)
//
//        guard let rows = handshakeViewModel?.rows else {
//            XCTFail()
//            return
//        }
//
//        XCTAssertEqual("", rows[0].privacyStatus)
    }
    
    //
    func testHandleChangeLanguagePressed() {
//        setupViewModel()
//        let languages = handshakeViewModel?.handleChangeLanguagePressed()
//        XCTAssertEqual([""], languages)
    }
    
    //
    func testDidSelectLanguage() {
        setupViewModel()
        let firstItemPosition = IndexPath(item: 0, section: 0)
        let catalan = "ca"
        
        //Before setting the new language, it MUST NOT be setted
        XCTAssertNotEqual(handshakeViewModel?.rows[0].currentLanguage, catalan)

        handshakeViewModel?.didSelectLanguage(forRowAt: firstItemPosition, language: catalan)
        let rowAfterLanguageChange = handshakeViewModel?.rows[0]
        
        //After setting the new language, it MUST be the same
        XCTAssertEqual(rowAfterLanguageChange?.currentLanguage, catalan)
    }
    
    //
    func testHandleToggleProtectionPressed() {
        
    }
    
    //
    func testShakeMotionDidEnd() {
        
    }
    
    /// Test get trustwords is being called.
    func testGetTrustwords() {
        let expectation = XCTestExpectation(description: "Get Trustwords Expectation")
        setupViewModel()
        let firstItemPosition = IndexPath(item: 0, section: 0)
        let mock = HandShakeUtilMock(getTrustwordsExpectation: expectation)
        handshakeViewModel?.handshakeUtil = mock
        let trustwords = handshakeViewModel?.generateTrustwords(indexPath: firstItemPosition)
        XCTAssertEqual(trustwords, HandShakeUtilMock.someTrustWords)
        let identity = identities[0]
        XCTAssertEqual(identity, mock.identity)
    }
}

extension HandshakeViewModelTest {
    private func setupViewModel() {
        if handshakeViewModel == nil {
            handshakeViewModel = HandshakeViewModel(identities:identities)
        }
    }
}

///MARK: - Mock Util Classes

class HandShakeUtilMock : HandShakeUtilProtocol {
    
    var getTrustwordsExpectation : XCTestExpectation?
    static let someTrustWords = "Dog"
    var identity : Identity?
    
    init(getTrustwordsExpectation : XCTestExpectation? = nil) {
        self.getTrustwordsExpectation = getTrustwordsExpectation
    }
    
    func getTrustwords(for identity: Identity, language: String, long: Bool) throws -> String? {
        getTrustwordsExpectation?.fulfill()
        self.identity = identity
        return HandShakeUtilMock.someTrustWords
    }
    
    func confirmTrust(for: Identity) throws {
        XCTFail("This mock MUST not implement this method")
    }
    
    func denyTrust(for: Identity) throws {
        XCTFail("This mock MUST not implement this method")
    }
    
    func resetTrust(for: Identity) throws {
        XCTFail("This mock MUST not implement this method")
    }
    
    static func denyTrust(for: Identity) throws {
         
    }
}


