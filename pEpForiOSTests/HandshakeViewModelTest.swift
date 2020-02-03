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
//        setupViewModel()
//        guard let numberOfRows = handshakeViewModel?.rows.count else {
//            XCTFail()
//            return
//        }
//        XCTAssertEqual(numberOfRows, numberOfRowsToGenerate)
    }

    //
    func testHandleRejectHandshakePressed() {
//        setupViewModel()
//        let firstItemPosition = IndexPath(item: 0, section: 0)
//        handshakeViewModel?.handleRejectHandshakePressed(at: firstItemPosition)
//
//        guard let rows = handshakeViewModel?.rows else {
//            XCTFail()
//            return
//        }
//
//        XCTAssertEqual("", rows[0].privacyStatus)
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
//        setupViewModel()
//        let firstItemPosition = IndexPath(row: 0, section: 0)
//        let row = handshakeViewModel?.rows[0]
//        handshakeViewModel?.didSelectLanguage(forRowAt: firstItemPosition, language: "ca")
//        let rowAfterLanguageChange = handshakeViewModel?.rows[0]
//        XCTAssertNotEqual(row?.currentLanguage, rowAfterLanguageChange?.currentLanguage)
    }
    
    //
    func testHandleToggleProtectionPressed() {
        
    }
    
    //
    func testShakeMotionDidEnd() {
        
    }
}

extension HandshakeViewModelTest {
    private func setupViewModel() {
        if handshakeViewModel == nil {
            handshakeViewModel = HandshakeViewModel(identities:identities)
        }
    }
}
