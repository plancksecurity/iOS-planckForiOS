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
    let delegate = MockDelegate()
    
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
        handshakeViewModel?.handshakeUtil = HandshakeUtilMock()
        handshakeViewModel?.handleRejectHandshakePressed(at: firstItemPosition)

        guard let _ = handshakeViewModel?.rows else {
            XCTFail("The handshakeViewModel can't be nil")
            return
        }
        
//        guard let firstRow = handshakeViewModel?.rows[0] else {
//            XCTFail("The first row must exist")
//            return
//        }

        //XCTAssertEqual("", firstRow.privacyStatus)
    }
    
    //
    func testHandleConfirmHandshakePressed() {
        setupViewModel()
        let confirm = expectation(description: "confirm")
        let mockDelegate = MockDelegate(didConfirmHandshakeExpectation: confirm)
        handshakeViewModel?.handshakeViewModelDelegate = mockDelegate
        let firstItemPosition = IndexPath(item: 0, section: 0)
        handshakeViewModel?.handleConfirmHandshakePressed(at: firstItemPosition)
        waitForExpectations(timeout: TestUtil.waitTime)
    }
    
    //
    func testHandleResetPressed() {
        let resetExp = expectation(description: "resetExp")

        setupViewModel()
        handshakeViewModel?.handshakeUtil = HandshakeUtilMock(resetExpectation: resetExp)

        let firstItemPosition = IndexPath(item: 0, section: 0)
        handshakeViewModel?.handleResetPressed(at: firstItemPosition)

//        guard let rows = handshakeViewModel?.rows else {
//            XCTFail()
//            return
//        }

        waitForExpectations(timeout: TestUtil.waitTime)
    }
    
//
//    func testHandleChangeLanguagePressed() {
//        setupViewModel()
//        handshakeViewModel?.handshakeUtil = HandshakeUtilMock()
//        let languages = handshakeViewModel?.handleChangeLanguagePressed()
//        XCTAssertEqual(handshakeViewModel?.handshakeUtil?.languagesList(), languages)
//    }
    
    //
    func testHandleToggleProtectionPressed() {
        setupViewModel()
        let toogleProtection = expectation(description: "toogle protection")
        let mockDelegate = MockDelegate(didChangeProtectionStatusExpectation:toogleProtection)
        handshakeViewModel?.handshakeViewModelDelegate = mockDelegate
        let firstItemPosition = IndexPath(item: 0, section: 0)
        handshakeViewModel?.handleToggleProtectionPressed(forRowAt: firstItemPosition)
        waitForExpectations(timeout: TestUtil.waitTime)
    }
    
    //
    func testShakeMotionDidEnd() {
        setupViewModel()

        let didShake = expectation(description: "didShake")
        let mockDelegate = MockDelegate(didEndShakeMotionExpectation: didShake)
        handshakeViewModel?.handshakeViewModelDelegate = mockDelegate
        handshakeViewModel?.shakeMotionDidEnd()
        waitForExpectations(timeout: TestUtil.waitTime)
    }
    
    /// Test get trustwords is being called.
    func testGetTrustwords() {
        let getTWExp = expectation(description: "Get Trustwords Expectation")
        setupViewModel()
        let firstItemPosition = IndexPath(item: 0, section: 0)
        let mock = HandshakeUtilMock(getTrustwordsExpectation: getTWExp)
        handshakeViewModel?.handshakeUtil = mock
        let trustwords = handshakeViewModel?.generateTrustwords(indexPath: firstItemPosition)
        XCTAssertEqual(trustwords, HandshakeUtilMock.someTrustWords)
        let identity = identities[0]
        XCTAssertEqual(identity, mock.identity)
        waitForExpectations(timeout: TestUtil.waitTime)
    }
    
    func testDidSelectLanguage() {
        setupViewModel()
        let didSelectLanguageExp = expectation(description: "didSelectLanguageExp")
        let mockDelegate = MockDelegate(didSelectLanguageExpectation: didSelectLanguageExp)
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
        let identity = SecretTestData().createWorkingCdIdentity(number: 2,
                                                                isMyself: true,
                                                                context: moc)
        let selfIdentity = Identity(cdObject: identity, context: moc)
        
        if handshakeViewModel == nil {
            handshakeViewModel = HandshakeViewModel(identities:identities,
                                                    selfIdentity: selfIdentity,
                                                    delegate: delegate)
        }
    }
}

///MARK: - Mock Util Classes

class HandshakeUtilMock : HandshakeUtilProtocol {
    
    var getTrustwordsExpectation : XCTestExpectation?
    var resetExpectation : XCTestExpectation?
    var confirmExpectation : XCTestExpectation?
    static let someTrustWords = "Dog"
    static let languages = ["en", "ca", "es"]
    var identity : Identity?
    
    
    init(getTrustwordsExpectation : XCTestExpectation? = nil,
         resetExpectation : XCTestExpectation? = nil,
         confirmExpectation : XCTestExpectation? = nil) {
        self.getTrustwordsExpectation = getTrustwordsExpectation
        self.resetExpectation = resetExpectation
        self.confirmExpectation = confirmExpectation
    }
    
    func languagesList() throws -> [String] {
        return HandshakeUtilMock.languages
    }
    
    func getTrustwords(forSelf: Identity, and: Identity, language: String, long: Bool) throws -> String? {
        getTrustwordsExpectation?.fulfill()
        self.identity = and
        return HandshakeUtilMock.someTrustWords
    }
    
    func confirmTrust(for: Identity) throws {

    }
    
    func denyTrust(for: Identity) throws {

    }
    
    func resetTrust(for: Identity) throws {
        resetExpectation?.fulfill()
    }
}


class MockDelegate : NSObject, HandshakeViewModelDelegate {
    
    var didEndShakeMotionExpectation: XCTestExpectation?
    var didResetHandshakeExpectation: XCTestExpectation?
    var didConfirmHandshakeExpectation: XCTestExpectation?
    var didRejectHandshakeExpectation: XCTestExpectation?
    var didChangeProtectionStatusExpectation: XCTestExpectation?
    var didSelectLanguageExpectation: XCTestExpectation?
    
    init(didEndShakeMotionExpectation: XCTestExpectation? = nil,
         didResetHandshakeExpectation: XCTestExpectation? = nil,
         didConfirmHandshakeExpectation: XCTestExpectation? = nil,
         didRejectHandshakeExpectation: XCTestExpectation? = nil,
         didChangeProtectionStatusExpectation: XCTestExpectation? = nil,
         didSelectLanguageExpectation: XCTestExpectation? = nil) {
        self.didEndShakeMotionExpectation = didEndShakeMotionExpectation
        self.didResetHandshakeExpectation = didResetHandshakeExpectation
        self.didConfirmHandshakeExpectation = didConfirmHandshakeExpectation
        self.didRejectHandshakeExpectation = didRejectHandshakeExpectation
        self.didChangeProtectionStatusExpectation = didChangeProtectionStatusExpectation
        self.didSelectLanguageExpectation = didSelectLanguageExpectation
    }

    func didEndShakeMotion() {
        didEndShakeMotionExpectation?.fulfill()
    }
    
    func didResetHandshake(forRowAt indexPath: IndexPath) {
        didResetHandshakeExpectation?.fulfill()
    }
    
    func didConfirmHandshake(forRowAt indexPath: IndexPath) {
        didConfirmHandshakeExpectation?.fulfill()
    }
    
    func didRejectHandshake(forRowAt indexPath: IndexPath) {
        didResetHandshakeExpectation?.fulfill()
    }
    
    func didChangeProtectionStatus(to status: HandshakeViewModel.ProtectionStatus) {
        didChangeProtectionStatusExpectation?.fulfill()
    }
    
    func didSelectLanguage(forRowAt indexPath: IndexPath) {
        didSelectLanguageExpectation?.fulfill()
    }
    
    func didToogleProtection(forRowAt indexPath: IndexPath) {
        didChangeProtectionStatusExpectation?.fulfill()
    }
}
