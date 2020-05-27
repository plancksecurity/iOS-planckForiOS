//IOS-2241 DOES NOT COMPILE
//
//  TrustManagementViewModelTest.swift
//  pEpForiOSTests
//
//  Created by Martin Brude on 31/01/2020.
//  Copyright © 2020 p≡p Security S.A. All rights reserved.
//

import XCTest
@testable import MessageModel
@testable import pEpForiOS

class TrustManagementViewModelTest: AccountDrivenTestBase {
    var selfIdentity : Identity?
    var trustManagementViewModel : TrustManagementViewModel?
    let numberOfRowsToGenerate = 1

    /// The row index available after the own account identity and parter identities
    var firstAccountIndexAvailable = 0

    var partnerIdentities = [Identity]()
    let delegate = MockTrustManagementViewModelHandler()
    
    override func setUp() {
        super.setUp()
        partnerIdentities = [Identity]()
        // Generate rows to test the handshake feature.
        for index in 0..<numberOfRowsToGenerate {
            // Note: The test account is generated from test data row 0, so don't use this.
            let identity = TestData().createPartnerIdentity(number: index + 1)
            identity.session.commit()
            partnerIdentities.append(identity)
        }

        firstAccountIndexAvailable = numberOfRowsToGenerate + 1
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
        let dataChangedExpectation = expectation(description: "dataChangedExpectation")
        let denyExpectation = expectation(description: "denyExpectation")
        let util = TrustManagementUtilMock(denyExpectation: denyExpectation)
        let mockDelegate = MockTrustManagementViewModelHandler(dataChangedExpectation: dataChangedExpectation)
        
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
        let languagesExpectation = expectation(description: "languages")
        setupViewModel(util: TrustManagementUtilMock(languagesExpectation: languagesExpectation))
        let languages = trustManagementViewModel?.languages
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
        trustManagementViewModel?.handleShakeMotionDidEnd()
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
        trustManagementViewModel?.handleShakeMotionDidEnd()
        ///Verify reset has been called only once.
        waitForExpectations(timeout: TestUtil.waitTime)
    }
    //MARTIN:
//    /// Test get trustwords is being called.
//    func testGetTrustwords() {
//        let getTrustwordsExpectation = expectation(description: "Get Trustwords Expectation")
//        let firstItemPosition = IndexPath(item: 0, section: 0)
//        let handshakeMock = TrustManagementUtilMock(getTrustwordsExpectation: getTrustwordsExpectation)
//        setupViewModel(util: handshakeMock)
//
//        trustManagementViewModel?.generateTrustwords(forRowAt: firstItemPosition, completion: { trustwords in
//            XCTAssertEqual(trustwords, TrustManagementUtilMock.someTrustWords)
//        })
//        waitForExpectations(timeout: TestUtil.waitTime)
//    }
    
//    //Test the Select language is being called
//    func testDidSelectLanguage() {
//        setupViewModel()
//        let didSelectLanguageExp = expectation(description: "didSelectLanguageExp")
//        let mockDelegate = MockTrustManagementViewModelHandler(didSelectLanguageExpectation: didSelectLanguageExp)
//        trustManagementViewModel?.delegate = mockDelegate
//        let catalan = "ca"
//        let firstItemPosition = IndexPath(item: 0, section: 0)
//        XCTAssertNotEqual(catalan, trustManagementViewModel?.rows[firstItemPosition.row].language)
//        trustManagementViewModel?.handleDidSelecteLanguage(forRowAt: firstItemPosition, language: catalan)
//        XCTAssertEqual(catalan, trustManagementViewModel?.rows[firstItemPosition.row].language)
//        waitForExpectations(timeout: TestUtil.waitTime)
//    }
    
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
        // Avoid collision with other identities (own account plus created partner identities).
        let selfNumber = firstAccountIndexAvailable
        
        let selfIdentity = TestData().createWorkingAccount(number: selfNumber).user
        selfIdentity.fingerprint = "fingerprints"
        selfIdentity.session.commit()
        
        if trustManagementViewModel == nil {
            let account1 = TestData().createWorkingAccount()
            account1.session.commit()
            let folder1 = Folder(name: "inbox", parent: nil, account: account1, folderType: .inbox)
            guard let from = partnerIdentities.first else  {
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
        if  let own = (message.allIdentities.filter { $0.isMySelf }.first),
            let other = (message.allIdentities.filter { !$0.isMySelf }.first) {
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
    func dataChanged(forRowAt indexPath: IndexPath) {
        //MARTIN: take care
        dataChangedExpectation?.fulfill()
    }

    
    var didEndShakeMotionExpectation: XCTestExpectation?
    var didResetHandshakeExpectation: XCTestExpectation?
    var didConfirmHandshakeExpectation: XCTestExpectation?
    var didDenyHandshakeExpectation: XCTestExpectation?
    var didChangeProtectionStatusExpectation: XCTestExpectation?
    var didSelectLanguageExpectation: XCTestExpectation?
    var didToogleLongTrustwordsExpectation: XCTestExpectation?
    var dataChangedExpectation: XCTestExpectation?

    init(didEndShakeMotionExpectation: XCTestExpectation? = nil,
         didResetHandshakeExpectation: XCTestExpectation? = nil,
         didConfirmHandshakeExpectation: XCTestExpectation? = nil,
         didDenyHandshakeExpectation: XCTestExpectation? = nil,
         didChangeProtectionStatusExpectation: XCTestExpectation? = nil,
         didSelectLanguageExpectation: XCTestExpectation? = nil,
         didToogleLongTrustwordsExpectation: XCTestExpectation? = nil,
         dataChangedExpectation: XCTestExpectation? = nil) {
        self.didEndShakeMotionExpectation = didEndShakeMotionExpectation
        self.didResetHandshakeExpectation = didResetHandshakeExpectation
        self.didConfirmHandshakeExpectation = didConfirmHandshakeExpectation
        self.didDenyHandshakeExpectation = didDenyHandshakeExpectation
        self.didChangeProtectionStatusExpectation = didChangeProtectionStatusExpectation
        self.didSelectLanguageExpectation = didSelectLanguageExpectation
        self.didToogleLongTrustwordsExpectation = didToogleLongTrustwordsExpectation
        self.dataChangedExpectation = dataChangedExpectation
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
