//
//  ClientCertificateImportPassword.swift
//  pEpForiOSTests
//
//  Created by Adam Kowalski on 04/03/2020.
//  Copyright © 2020 p≡p Security S.A. All rights reserved.
//

import XCTest
@testable import pEpForiOS

final class ClientCertificatePasswordViewModelTest: XCTestCase {

    private let expHandleCancelButtonPressed = XCTestExpectation(description: "Waiting for delegate")
    private let expHandleOkButtonPressed = XCTestExpectation(description: "Waiting for passwordChangeDelegate")
    private var vm: ClientCertificatePasswordViewModel?

    override func setUp() {
        vm = ClientCertificatePasswordViewModel(delegate: self,
                                                passwordChangeDelegate: self)
    }

    override func tearDown() {
        vm = nil
    }

    func testSth() {
        XCTAssertNotNil(vm, "vm is not set!")
        vm?.delegate?.dismiss()
    }

    func testhandleOkButtonPressedTest() {
        XCTAssertNotNil(vm, "vm is not set!")
        vm?.handleOkButtonPressed(password: Constant.password)
        wait(for: [expHandleOkButtonPressed], timeout: 2)
    }

    func testHandleCancelButtonPressed() {
        XCTAssertNotNil(vm, "vm is not set!")
        vm?.handleCancelButtonPresed()
        wait(for: [expHandleCancelButtonPressed], timeout: 2)
    }
}

extension ClientCertificatePasswordViewModelTest: ClientCertificatePasswordViewModelDelegate {
    func dismiss() {
        expHandleCancelButtonPressed.fulfill()
    }
}

extension ClientCertificatePasswordViewModelTest: ClientCertificatePasswordViewModelPasswordChangeDelegate {
    func didEnter(password: String) {
        let exp = Constant.password
        XCTAssertEqual(password, exp)
        expHandleOkButtonPressed.fulfill()
    }
}

// MARK: - Mock Data

private struct Constant {
    static let password = "1234"
}
