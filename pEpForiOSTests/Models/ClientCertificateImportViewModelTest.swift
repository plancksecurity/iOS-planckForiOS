//
//  ClientCertificateImportPassword.swift
//  pEpForiOSTests
//
//  Created by Adam Kowalski on 04/03/2020.
//  Copyright © 2020 p≡p Security S.A. All rights reserved.
//
//"Certificate_001.p12", password: "uiae"
import XCTest
@testable import pEpForiOS

final class ClientCertificateImportViewModelTest: XCTestCase {

    private var bundle: Bundle!
    private var vm: ClientCertificateImportViewModel?
    private var fakeURL: URL!

    override func setUp() {
        bundle = Bundle(for: type(of: self))
        fakeURL = bundle.url(forResource: "Certificate_001", withExtension: "p12")
    }

    override func tearDown() {
        vm = nil
    }

    func testHandleOkButtonPressed() {
        let dismissExpectation = expectation(description: "dismissExpectation")
        let delegate = ClientCertificateImportViewModelDelegateMock(dismissExpectation: dismissExpectation)
        vm = ClientCertificateImportViewModel(certificateUrl: fakeURL, delegate: delegate)
        vm?.importClientCertificate()
        XCTAssertNotNil(vm, "vm is not set!")
        vm?.importClientCertificate()
        vm?.handlePassphraseEntered(pass: Constant.password)
        waitForExpectations(timeout: TestUtil.waitTime)
    }
    
    func testHandleOkButtonPressedWithWrongPassword() {
        let wrongPasswordExpectation = expectation(description: "wrongPasswordExpectation")
        let delegate = ClientCertificateImportViewModelDelegateMock(wrongURLExpectation: wrongPasswordExpectation)
        vm = ClientCertificateImportViewModel(certificateUrl: fakeURL, delegate: delegate)
        vm?.importClientCertificate()
        XCTAssertNotNil(vm, "vm is not set!")
        vm?.importClientCertificate()
        vm?.handlePassphraseEntered(pass: Constant.wrongPassword)
        waitForExpectations(timeout: TestUtil.waitTime)
    }

    func testHandleCancelButtonPressed() {
        let dismissExpectation = expectation(description: "dismissExpectation")
        let delegate = ClientCertificateImportViewModelDelegateMock(dismissExpectation: dismissExpectation)
        vm = ClientCertificateImportViewModel(certificateUrl: fakeURL, delegate: delegate)
        vm?.importClientCertificate()
        XCTAssertNotNil(vm, "vm is not set!")
        vm?.importClientCertificate()
        vm?.handleCancelButtonPresed()
        waitForExpectations(timeout: TestUtil.waitTime)
    }
}

class ClientCertificateImportViewModelDelegateMock: ClientCertificateImportViewModelDelegate {
    let wrongFileExpectation: XCTestExpectation?
    let wrongURLExpectation: XCTestExpectation?
    let dismissExpectation: XCTestExpectation?
    
    init(wrongFileExpectation: XCTestExpectation? = nil, dismissExpectation: XCTestExpectation? = nil, wrongURLExpectation: XCTestExpectation? = nil) {
        self.wrongFileExpectation = wrongFileExpectation
        self.wrongURLExpectation = wrongURLExpectation
        self.dismissExpectation = dismissExpectation
    }
    
    func showError(type: ImportCertificateError, dissmisAfterError: Bool) {
        switch type {
        case .corruptedFile:
            if let expectation = wrongFileExpectation, wrongURLExpectation == nil {
                expectation.fulfill()
            } else {
                XCTFail()
            }
        case .wrongPassword:
            if let expectation = wrongURLExpectation, wrongFileExpectation == nil {
                expectation.fulfill()
            } else {
                XCTFail()
            }
        case .noPermissions:
            XCTFail()
        }
    }

    func dismiss() {
        if wrongFileExpectation == nil && wrongURLExpectation == nil {
            dismissExpectation?.fulfill()
        } else {
            XCTFail()
        }
    }
}

// MARK: - Mock Data

private struct Constant {
    static let wrongPassword = "1234"
    static let password = "uiae"
}

