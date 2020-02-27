//
//  TrustManagementViewModelTest.swift
//  pEpForiOSTests
//
//  Created by Martin Brude on 31/01/2020.
//  Copyright © 2020 p≡p Security S.A. All rights reserved.
//

import XCTest
import CoreData
@testable import MessageModel
@testable import pEpForiOS

class TrustManagementViewModelTest: CoreDataDrivenTestBase {
    var selfIdentity : Identity?
    var trustManagementViewModel : TrustManagementViewModel?
    let numberOfRowsToGenerate = 1
    var identities = [Identity]()
    let delegate = MockTrustManagementViewModelHandler()
    
    override func setUp() {
        super.setUp()
        identities = [Identity]()
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
        trustManagementViewModel = nil
    }
    
    /// Test the number of generated rows is equal to the number of rows to generate
    func testNumberOfRows() {
        setupViewModel()
        guard let numberOfRows = trustManagementViewModel?.rows.count else {
            XCTFail("The trustManagementViewModel can't be nil")
            return
        }
        XCTAssertEqual(numberOfRows, numberOfRowsToGenerate)
    }
    
    //Test Reject Handshake Pressed
    func testHandleRejectHandshakePressed() {
        let didDenyExpectation = expectation(description: "didDenyExpectation")
        let denyExpectation = expectation(description: "denyExpectation")
        let util = TrustManagementUtilMock(denyExpectation: denyExpectation)
        let mockDelegate = MockTrustManagementViewModelHandler(didDenyHandshakeExpectation: didDenyExpectation)
        
        setupViewModel(util: util)
        trustManagementViewModel?.delegate = mockDelegate
        
        let firstItemPosition = IndexPath(item: 0, section: 0)
        trustManagementViewModel?.handleRejectHandshakePressed(at: firstItemPosition)
        waitForExpectations(timeout: TestUtil.waitTime)
    }
    
    // Test handshake confirmation: utils and delegate methods must be called.
    func testHandleConfirmHandshakePressed() {
        let confirmExpectation = expectation(description: "confirm")
        let didConfirmExpectation = expectation(description: "didConfirm")
        let mockDelegate = MockTrustManagementViewModelHandler(didConfirmHandshakeExpectation: didConfirmExpectation)
        let util = TrustManagementUtilMock(confirmExpectation: confirmExpectation)
        setupViewModel(util: util)
        trustManagementViewModel?.delegate = mockDelegate
        
        let firstItemPosition = IndexPath(item: 0, section: 0)
        trustManagementViewModel?.handleConfirmHandshakePressed(at: firstItemPosition)
        waitForExpectations(timeout: TestUtil.waitTime)
    }
    
    // Test trustManagementViewModel reset: utils and delegate methods must be called.
    func testHandleResetPressed() {
        let didResetExpectation = expectation(description: "didReset")
        let resetExpectation = expectation(description: "reset")
        let mockDelegate = MockTrustManagementViewModelHandler(didResetHandshakeExpectation: didResetExpectation)
        let firstItemPosition = IndexPath(item: 0, section: 0)
        
        setupViewModel(util: TrustManagementUtilMock(resetExpectation: resetExpectation))
        trustManagementViewModel?.delegate = mockDelegate
        trustManagementViewModel?.handleResetPressed(forRowAt: firstItemPosition)
        waitForExpectations(timeout: TestUtil.waitTime)
    }
    
    //Test Change Language Pressed
    func testHandleChangeLanguagePressed() {
        let firstItemPosition = IndexPath(item: 0, section: 0)
        let languagesExpectation = expectation(description: "languages")
        setupViewModel(util: TrustManagementUtilMock(languagesExpectation: languagesExpectation))
        let languages = trustManagementViewModel?.handleChangeLanguagePressed(forRowAt: firstItemPosition)
        XCTAssertEqual(TrustManagementUtilMock.languages, languages)
        waitForExpectations(timeout: TestUtil.waitTime)
    }
    
    //Test Toogle Protection Pressed
    func testHandleToggleProtectionPressed() {
        let mockDelegate = MockTrustManagementViewModelHandler()
        setupViewModel()
        trustManagementViewModel?.delegate = mockDelegate
        let before = trustManagementViewModel?.pEpProtected
        trustManagementViewModel?.handleToggleProtectionPressed()
        let after = trustManagementViewModel?.pEpProtected
        XCTAssertTrue(before != after)
    }
    
    //Test Shake Motion
    func testShakeMotionDidEnd() {
        let firstItemPosition = IndexPath(item: 0, section: 0)
        let didEndShakeMotionExpectation = expectation(description: "didShake")
        let didConfirmExpectation = expectation(description: "didConfirm")
        let mockDelegate = MockTrustManagementViewModelHandler(didEndShakeMotionExpectation: didEndShakeMotionExpectation,
                                                         didConfirmHandshakeExpectation: didConfirmExpectation)
        setupViewModel()
        trustManagementViewModel?.delegate = mockDelegate
        trustManagementViewModel?.handleConfirmHandshakePressed(at: firstItemPosition)
        trustManagementViewModel?.shakeMotionDidEnd()
        waitForExpectations(timeout: TestUtil.waitTime)
    }
    
    func testUndoRejectOnShakeMotion() {
        let firstItemPosition = IndexPath(item: 0, section: 0)
        let didShake = expectation(description: "didShake")
        let didDeny = expectation(description: "didDeny")
        let mockDelegate = MockTrustManagementViewModelHandler(didEndShakeMotionExpectation: didShake,
                                                         didDenyHandshakeExpectation: didDeny)
        setupViewModel()
        trustManagementViewModel?.delegate = mockDelegate
        //Reject handshake
        trustManagementViewModel?.handleRejectHandshakePressed(at: firstItemPosition)
        //Gesture for undo
        trustManagementViewModel?.shakeMotionDidEnd()
        ///Verify reset has been called only once.
        waitForExpectations(timeout: TestUtil.waitTime)
    }
    
    /// Test get trustwords is being called.
    func testGetTrustwords() {
        let getTrustwordsExpectation = expectation(description: "Get Trustwords Expectation")
        let firstItemPosition = IndexPath(item: 0, section: 0)
        let handshakeMock = TrustManagementUtilMock(getTrustwordsExpectation: getTrustwordsExpectation)
        setupViewModel(util: handshakeMock)
        
        trustManagementViewModel?.generateTrustwords(forRowAt: firstItemPosition, completion: { trustwords in
            XCTAssertEqual(trustwords, TrustManagementUtilMock.someTrustWords)
        })
        waitForExpectations(timeout: TestUtil.waitTime)
    }
    
    //Test the Select language is being called
    func testDidSelectLanguage() {
        setupViewModel()
        let didSelectLanguageExp = expectation(description: "didSelectLanguageExp")
        let mockDelegate = MockTrustManagementViewModelHandler(didSelectLanguageExpectation: didSelectLanguageExp)
        trustManagementViewModel?.delegate = mockDelegate
        let catalan = "ca"
        let firstItemPosition = IndexPath(item: 0, section: 0)
        XCTAssertNotEqual(catalan, trustManagementViewModel?.rows[firstItemPosition.row].currentLanguage)
        trustManagementViewModel?.didSelectLanguage(forRowAt: firstItemPosition, language: catalan)
        XCTAssertEqual(catalan, trustManagementViewModel?.rows[firstItemPosition.row].currentLanguage)
        waitForExpectations(timeout: TestUtil.waitTime)
    }
    
    func testDidToogleLongTrustwords() {
        let firstItemPosition = IndexPath(item: 0, section: 0)

        let didToogleLongTrustwordsExpectation = expectation(description: "didToogleLongTrustwords")
        let mockDelegate = MockTrustManagementViewModelHandler(didToogleLongTrustwordsExpectation: didToogleLongTrustwordsExpectation)
        setupViewModel()

        trustManagementViewModel?.delegate = mockDelegate
        trustManagementViewModel?.handleToggleLongTrustwords(forRowAt: firstItemPosition)
        waitForExpectations(timeout: TestUtil.waitTime)
    }
}

extension TrustManagementViewModelTest {
    private func setupViewModel(util : TrustManagementUtilProtocol? = nil) {
        //Avoid collision with others identity numbers.
        let selfNumber = numberOfRowsToGenerate + 1
        
        let cdIdentity: CdIdentity = SecretTestData().createWorkingCdIdentity(number:selfNumber,
                                                                              isMyself: true,
                                                                              context: moc)
        let selfIdentity = Identity(cdObject: cdIdentity, context: moc)
        selfIdentity.fingerprint = "fingerprints"
        selfIdentity.save()
        moc.saveAndLogErrors()
        
        if trustManagementViewModel == nil {
            let account1 = SecretTestData().createWorkingAccount(context: moc)
            account1.save()
            let folder1 = Folder(name: "inbox", parent: nil, account: account1, folderType: .inbox)
            guard let from = identities.first else  {
                XCTFail()
                return
            }
            let message = TestUtil.createMessage(inFolder: folder1, from:from, tos: [selfIdentity])
            
            trustManagementViewModel = TrustManagementViewModel(message: message,
                                                                pEpProtectionModifyable: true,
                                                                delegate: nil,
                                                                protectionStateChangeDelegate: ComposeViewModel(),
                                                                trustManagementUtil: util ?? TrustManagementUtilMock())
        }
    }
}


///MARK: - Mock Util Classes

class TrustManagementUtilMock: TrustManagementUtilProtocol {
    func handshakeCombinations(message: Message) -> [TrustManagementUtil.HandshakeCombination] {
        
        if let own = message.allIdentities.filter({$0.isMySelf == true}).first,
            let other = message.allIdentities.filter({$0.isMySelf != true}).first {
            return [TrustManagementUtil.HandshakeCombination(ownIdentity:own, partnerIdentity: other)]
        }
        
        return [TrustManagementUtil.HandshakeCombination]()
    }
    
    func handshakeCombinations(identities: [Identity]) -> [TrustManagementUtil.HandshakeCombination] {
        return [TrustManagementUtil.HandshakeCombination]()
    }

    var getTrustwordsExpectation: XCTestExpectation?
    var resetExpectation: XCTestExpectation?
    var confirmExpectation: XCTestExpectation?
    var denyExpectation: XCTestExpectation?
    var languagesExpectation: XCTestExpectation?
    var undoExpectation: XCTestExpectation?
    
    static let someTrustWords = "Dog"
    static let languages = ["en", "ca", "es"]
    var identity : Identity?
    
    init(getTrustwordsExpectation: XCTestExpectation? = nil,
         resetExpectation: XCTestExpectation? = nil,
         confirmExpectation: XCTestExpectation? = nil,
         denyExpectation: XCTestExpectation? = nil,
         languagesExpectation: XCTestExpectation? = nil,
         undoExpectation: XCTestExpectation? = nil){
        self.getTrustwordsExpectation = getTrustwordsExpectation
        self.resetExpectation = resetExpectation
        self.confirmExpectation = confirmExpectation
        self.denyExpectation = denyExpectation
        self.languagesExpectation = languagesExpectation
        self.undoExpectation = undoExpectation
    }
    
    func languagesList() -> [String]? {
        languagesExpectation?.fulfill()
        return TrustManagementUtilMock.languages
    }
    
    func getTrustwords(for forSelf: Identity, and: Identity, language: String, long: Bool) -> String? {
        self.identity = and

        if getTrustwordsExpectation != nil {
            getTrustwordsExpectation?.fulfill()
            getTrustwordsExpectation = nil
        }

        return TrustManagementUtilMock.someTrustWords
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
    
    func getFingerprint(for Identity: Identity) -> String? {
        return nil
    }
    
    func undoMisstrustOrTrust(for partnerIdentity: Identity, fingerprint: String?) {
        undoExpectation?.fulfill()
    }
    
    func resetTrust(for partnerIdentity: Identity?) {
        resetExpectation?.fulfill()
    }
}

/// Use this mock class to verify the calls on the delegate are being performed
class MockTrustManagementViewModelHandler : TrustManagementViewModelDelegate {
    
    var didEndShakeMotionExpectation: XCTestExpectation?
    var didResetHandshakeExpectation: XCTestExpectation?
    var didConfirmHandshakeExpectation: XCTestExpectation?
    var didDenyHandshakeExpectation: XCTestExpectation?
    var didChangeProtectionStatusExpectation: XCTestExpectation?
    var didSelectLanguageExpectation: XCTestExpectation?
    var didToogleLongTrustwordsExpectation: XCTestExpectation?
    init(didEndShakeMotionExpectation: XCTestExpectation? = nil,
         didResetHandshakeExpectation: XCTestExpectation? = nil,
         didConfirmHandshakeExpectation: XCTestExpectation? = nil,
         didDenyHandshakeExpectation: XCTestExpectation? = nil,
         didChangeProtectionStatusExpectation: XCTestExpectation? = nil,
         didSelectLanguageExpectation: XCTestExpectation? = nil,
         didToogleLongTrustwordsExpectation: XCTestExpectation? = nil) {
        self.didEndShakeMotionExpectation = didEndShakeMotionExpectation
        self.didResetHandshakeExpectation = didResetHandshakeExpectation
        self.didConfirmHandshakeExpectation = didConfirmHandshakeExpectation
        self.didDenyHandshakeExpectation = didDenyHandshakeExpectation
        self.didChangeProtectionStatusExpectation = didChangeProtectionStatusExpectation
        self.didSelectLanguageExpectation = didSelectLanguageExpectation
        self.didToogleLongTrustwordsExpectation = didToogleLongTrustwordsExpectation
    }
    func reload() {
        if didEndShakeMotionExpectation != nil {
            didEndShakeMotionExpectation?.fulfill()
            didEndShakeMotionExpectation = nil
        }
        if didResetHandshakeExpectation != nil {
            didResetHandshakeExpectation?.fulfill()
            didResetHandshakeExpectation = nil
        }
        if didConfirmHandshakeExpectation != nil {
            didConfirmHandshakeExpectation?.fulfill()
            didConfirmHandshakeExpectation = nil
        }
        if didDenyHandshakeExpectation != nil {
            didDenyHandshakeExpectation?.fulfill()
            didDenyHandshakeExpectation = nil
        }
        if didSelectLanguageExpectation != nil {
            didSelectLanguageExpectation?.fulfill()
            didSelectLanguageExpectation = nil
        }
        if didToogleLongTrustwordsExpectation != nil {
            didToogleLongTrustwordsExpectation?.fulfill()
            didToogleLongTrustwordsExpectation = nil
        }
    }

    func didToogleProtection(forRowAt indexPath: IndexPath) {
        if let expectation = didChangeProtectionStatusExpectation {
            expectation.fulfill()
        } else {
            XCTFail("didToogleProtection failed")
        }
    }
}
