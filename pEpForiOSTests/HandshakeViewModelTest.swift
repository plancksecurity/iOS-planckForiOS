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
    var selfIdentity : Identity?
    var handshakeViewModel : HandshakeViewModel?
    let numberOfRowsToGenerate = 1
    var identities = [Identity]()
    let delegate = MockHandshakeViewModelHandler()
    
    override func setUp() {
        super.setUp()
        
        // Generate rows to test the handshake feature
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
        handshakeViewModel = nil
    }

    /// Test the number of generated rows is equal to the number of rows to generate
    func testNumberOfRows() {
        setupViewModel()
        guard let numberOfRows = handshakeViewModel?.rows.count else {
            XCTFail("The handshakeViewModel can't be nil")
            return
        }
        XCTAssertEqual(numberOfRows, numberOfRowsToGenerate)
    }
    
    //Test Reject Handshake Pressed
    func testHandleRejectHandshakePressed() {
        setupViewModel()
        let didDenyExpectation = expectation(description: "didDenyExpectation")
        let mockDelegate = MockHandshakeViewModelHandler(didDenyHandshakeExpectation: didDenyExpectation)
        handshakeViewModel?.handshakeViewModelDelegate = mockDelegate
        
        let denyExpectation = expectation(description: "denyExpectation")
        handshakeViewModel?.handshakeUtil = HandshakeUtilMock(denyExpectation: denyExpectation)
        let firstItemPosition = IndexPath(item: 0, section: 0)
        handshakeViewModel?.handleRejectHandshakePressed(at: firstItemPosition)
        waitForExpectations(timeout: TestUtil.waitTime)
    }
    
    // Test handshake confirmation: utils and delegate methods must be called.
    func testHandleConfirmHandshakePressed() {
        setupViewModel()
        let didConfirmExpectation = expectation(description: "didConfirm")
        let mockDelegate = MockHandshakeViewModelHandler(didConfirmHandshakeExpectation:
            didConfirmExpectation)
        handshakeViewModel?.handshakeViewModelDelegate = mockDelegate
        let confirmExpectation = expectation(description: "confirm")
        handshakeViewModel?.handshakeUtil = HandshakeUtilMock(confirmExpectation: confirmExpectation)
        let firstItemPosition = IndexPath(item: 0, section: 0)
        handshakeViewModel?.handleConfirmHandshakePressed(at: firstItemPosition)
        waitForExpectations(timeout: TestUtil.waitTime)
    }
    
    // Test handshake reset: utils and delegate methods must be called.
    func testHandleResetPressed() {
        setupViewModel()
        let didResetExpectation = expectation(description: "didReset")
        let mockDelegate = MockHandshakeViewModelHandler(didResetHandshakeExpectation: didResetExpectation)
        handshakeViewModel?.handshakeViewModelDelegate = mockDelegate
        let resetExpectation = expectation(description: "reset")
        handshakeViewModel?.handshakeUtil = HandshakeUtilMock(resetExpectation: resetExpectation)
        let firstItemPosition = IndexPath(item: 0, section: 0)
        handshakeViewModel?.handleResetPressed(at: firstItemPosition)
        waitForExpectations(timeout: TestUtil.waitTime)
    }

    //Test Change Language Pressed
    func testHandleChangeLanguagePressed() {
        setupViewModel()
        let languagesExpectation = expectation(description: "languages")
        handshakeViewModel?.handshakeUtil = HandshakeUtilMock(languagesExpectation: languagesExpectation)
        let languages = handshakeViewModel?.handleChangeLanguagePressed()
        XCTAssertEqual(HandshakeUtilMock.languages, languages)
        waitForExpectations(timeout: TestUtil.waitTime)
    }
    
    //Test Toogle Protection Pressed
    func testHandleToggleProtectionPressed() {
        setupViewModel()
        let toogleProtection = expectation(description: "toogle protection")
        let mockDelegate = MockHandshakeViewModelHandler(didChangeProtectionStatusExpectation:toogleProtection)
        handshakeViewModel?.handshakeViewModelDelegate = mockDelegate
        let firstItemPosition = IndexPath(item: 0, section: 0)
        handshakeViewModel?.handleToggleProtectionPressed(forRowAt: firstItemPosition)
        waitForExpectations(timeout: TestUtil.waitTime)
    }
    
    //Test Shake Motion
    func testShakeMotionDidEnd() {
        setupViewModel()
        let didShake = expectation(description: "didShake")
        let mockDelegate = MockHandshakeViewModelHandler(didEndShakeMotionExpectation: didShake)
        handshakeViewModel?.handshakeViewModelDelegate = mockDelegate
        handshakeViewModel?.shakeMotionDidEnd()
        waitForExpectations(timeout: TestUtil.waitTime)
    }
    
    func testUndoConfirmOnShakeMotion() {
        setupViewModel()
        
        let firstItemPosition = IndexPath(item: 0, section: 0)
        let didShake = expectation(description: "didShake")
        let didReset = expectation(description: "didReset")
        let didConfirm = expectation(description: "didConfirm")
        let mockDelegate = MockHandshakeViewModelHandler(didEndShakeMotionExpectation: didShake,
                                                         didResetHandshakeExpectation: didReset,
                                                         didConfirmHandshakeExpectation: didConfirm)

        handshakeViewModel?.handshakeViewModelDelegate = mockDelegate
        
        //Confirm handshake
        handshakeViewModel?.handleConfirmHandshakePressed(at: firstItemPosition)
        
        //Gesture for undo
        handshakeViewModel?.shakeMotionDidEnd()

        ///Verify reset has been called only once.
        waitForExpectations(timeout: TestUtil.waitTime)
    }
    
    func testUndoRejectOnShakeMotion() {
           setupViewModel()
           
           let firstItemPosition = IndexPath(item: 0, section: 0)
           let didShake = expectation(description: "didShake")
           let didReset = expectation(description: "didReset")
           let didDeny = expectation(description: "didDeny")
           let mockDelegate = MockHandshakeViewModelHandler(didEndShakeMotionExpectation: didShake,
                                                            didResetHandshakeExpectation: didReset,
                                                            didDenyHandshakeExpectation: didDeny)

           handshakeViewModel?.handshakeViewModelDelegate = mockDelegate
           
           //Reject handshake
           handshakeViewModel?.handleRejectHandshakePressed(at: firstItemPosition)
           
           //Gesture for undo
           handshakeViewModel?.shakeMotionDidEnd()

           ///Verify reset has been called only once.
           waitForExpectations(timeout: TestUtil.waitTime)
       }
    
    /// Test get trustwords is being called.
    func testGetTrustwords() {
        let getTWExp = expectation(description: "Get Trustwords Expectation")
        setupViewModel()
        let firstItemPosition = IndexPath(item: 0, section: 0)
        let handshakeMock = HandshakeUtilMock(getTrustwordsExpectation: getTWExp)
        handshakeViewModel?.handshakeUtil = handshakeMock
        let trustwords = handshakeViewModel?.generateTrustwords(indexPath: firstItemPosition)
        XCTAssertEqual(trustwords, HandshakeUtilMock.someTrustWords)
        let identity = identities[firstItemPosition.row]
        XCTAssertEqual(identity, handshakeMock.identity)
        waitForExpectations(timeout: TestUtil.waitTime)
    }
    
    //Test the Select language is being called
    func testDidSelectLanguage() {
        setupViewModel()
        let didSelectLanguageExp = expectation(description: "didSelectLanguageExp")
        let mockDelegate = MockHandshakeViewModelHandler(didSelectLanguageExpectation: didSelectLanguageExp)
        handshakeViewModel?.handshakeViewModelDelegate = mockDelegate
        let catalan = "ca"
        let firstItemPosition = IndexPath(item: 0, section: 0)
        XCTAssertNotEqual(catalan, handshakeViewModel?.rows[firstItemPosition.row].currentLanguage)
        handshakeViewModel?.didSelectLanguage(forRowAt: firstItemPosition, language: catalan)
        XCTAssertEqual(catalan, handshakeViewModel?.rows[firstItemPosition.row].currentLanguage)
        waitForExpectations(timeout: TestUtil.waitTime)
    }
}

extension HandshakeViewModelTest {
    private func setupViewModel() {
        //Avoid collision with others identity numbers.
        let selfNumber = numberOfRowsToGenerate + 1
        
        let cdIdentity: CdIdentity = SecretTestData().createWorkingCdIdentity(number:selfNumber,
                                                                              isMyself: true,
                                                                              context: moc)
        let selfIdentity = Identity(cdObject: cdIdentity, context: moc)
        let mockedUtil = HandshakeUtilMock()
        if handshakeViewModel == nil {
            handshakeViewModel = HandshakeViewModel(identities:identities,
                                                    selfIdentity: selfIdentity,
                                                    delegate: delegate,
                                                    handshakeUtil:mockedUtil)
        }
    }
}

///MARK: - Mock Util Classes

class HandshakeUtilMock: HandshakeUtilProtocol {
    var getTrustwordsExpectation: XCTestExpectation?
    var resetExpectation: XCTestExpectation?
    var confirmExpectation: XCTestExpectation?
    var denyExpectation: XCTestExpectation?
    var languagesExpectation: XCTestExpectation?
    
    static let someTrustWords = "Dog"
    static let languages = ["en", "ca", "es"]
    var identity : Identity?
    
    init(getTrustwordsExpectation: XCTestExpectation? = nil,
         resetExpectation: XCTestExpectation? = nil,
         confirmExpectation: XCTestExpectation? = nil,
         denyExpectation: XCTestExpectation? = nil,
         languagesExpectation: XCTestExpectation? = nil){
        self.getTrustwordsExpectation = getTrustwordsExpectation
        self.resetExpectation = resetExpectation
        self.confirmExpectation = confirmExpectation
        self.denyExpectation = denyExpectation
        self.languagesExpectation = languagesExpectation
    }

    func languagesList() -> [String]? {
        languagesExpectation?.fulfill()
        return HandshakeUtilMock.languages
    }
    
    func getTrustwords(for forSelf: Identity, and: Identity, language: String, long: Bool) -> String? {
        self.identity = and
        getTrustwordsExpectation?.fulfill()
        return HandshakeUtilMock.someTrustWords
    }
    
    func confirmTrust(for identity: Identity) {
        confirmExpectation?.fulfill()
    }
    
    func denyTrust(for identity: Identity) {
        denyExpectation?.fulfill()
    }
    
    func resetTrust(for partnerIdentity: Identity, fingerprints: String?) {
        resetExpectation?.fulfill()
    }
    
    func getFingerprints(for Identity: Identity) -> String? {
        return nil
    }
}

/// Use this mock class to verify the calls on the delegate are being performed
class MockHandshakeViewModelHandler : HandshakeViewModelDelegate {
    
    var didEndShakeMotionExpectation: XCTestExpectation?
    var didResetHandshakeExpectation: XCTestExpectation?
    var didConfirmHandshakeExpectation: XCTestExpectation?
    var didDenyHandshakeExpectation: XCTestExpectation?
    var didChangeProtectionStatusExpectation: XCTestExpectation?
    var didSelectLanguageExpectation: XCTestExpectation?
    
    init(didEndShakeMotionExpectation: XCTestExpectation? = nil,
         didResetHandshakeExpectation: XCTestExpectation? = nil,
         didConfirmHandshakeExpectation: XCTestExpectation? = nil,
         didDenyHandshakeExpectation: XCTestExpectation? = nil,
         didChangeProtectionStatusExpectation: XCTestExpectation? = nil,
         didSelectLanguageExpectation: XCTestExpectation? = nil) {
        self.didEndShakeMotionExpectation = didEndShakeMotionExpectation
        self.didResetHandshakeExpectation = didResetHandshakeExpectation
        self.didConfirmHandshakeExpectation = didConfirmHandshakeExpectation
        self.didDenyHandshakeExpectation = didDenyHandshakeExpectation
        self.didChangeProtectionStatusExpectation = didChangeProtectionStatusExpectation
        self.didSelectLanguageExpectation = didSelectLanguageExpectation
    }

    func didEndShakeMotion() {
        if let expectation = didEndShakeMotionExpectation {
            expectation.fulfill()
        } else {
            XCTFail()
        }
    }
    
    func didResetHandshake(forRowAt indexPath: IndexPath) {
        if let expectation = didResetHandshakeExpectation {
            expectation.fulfill()
        } else {
            XCTFail()
        }
    }
    
    func didConfirmHandshake(forRowAt indexPath: IndexPath) {
        if let expectation = didConfirmHandshakeExpectation {
            expectation.fulfill()
        } else {
            XCTFail()
        }
    }
    
    func didRejectHandshake(forRowAt indexPath: IndexPath) {
        if let expectation = didDenyHandshakeExpectation {
            expectation.fulfill()
        } else {
            XCTFail()
        }
    }
    
    func didChangeProtectionStatus(to status: HandshakeViewModel.ProtectionStatus) {
        if let expectation = didChangeProtectionStatusExpectation {
            expectation.fulfill()
        } else {
            XCTFail()
        }
    }
    
    func didSelectLanguage(forRowAt indexPath: IndexPath) {
        if let expectation = didSelectLanguageExpectation {
            expectation.fulfill()
        } else {
            XCTFail()
        }
    }
    
    func didToogleProtection(forRowAt indexPath: IndexPath) {
        if let expectation = didChangeProtectionStatusExpectation {
            expectation.fulfill()
        } else {
            XCTFail()
        }
    }
}
