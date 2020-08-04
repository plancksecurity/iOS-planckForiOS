//IOS-2241 DOES NOT COMPILE
////
////  ClientCertificateImportPassword.swift
////  pEpForiOSTests
////
////  Created by Adam Kowalski on 04/03/2020.
////  Copyright © 2020 p≡p Security S.A. All rights reserved.
////
//
//import XCTest
//@testable import pEpForiOS
//
//final class ClientCertificatePasswordViewModelTest: XCTestCase {
//
//    private let expHandleCancelButtonPressed = XCTestExpectation(description: "Waiting for delegate")
//    private let expHandleOkButtonPressed = XCTestExpectation(description: "Waiting for passwordChangeDelegate")
//    private var vm: ClientCertificateImportViewModel?
//    private var fakeURL = URL(fileURLWithPath: "")
//
//    override func setUp() {
//        vm = ClientCertificateImportViewModel(certificateUrl: fakeURL, delegate: self,
//                                                passwordChangeDelegate: self)
//    }
//
//    override func tearDown() {
//        vm = nil
//    }
//
//    func testhandleOkButtonPressedTest() {
//        XCTAssertNotNil(vm, "vm is not set!")
//        vm?.handlePassphraseEntered(pass: Constant.password)
//        wait(for: [expHandleOkButtonPressed], timeout: 2)
//    }
//
//    func testHandleCancelButtonPressed() {
//        XCTAssertNotNil(vm, "vm is not set!")
//        vm?.handleCancelButtonPresed()
//        wait(for: [expHandleCancelButtonPressed], timeout: 2)
//    }
//}
//
//extension ClientCertificatePasswordViewModelTest: ClientCertificateImportViewModelDelegate {
//    func showError(type: ImportCertificateError, dissmisAfterError: Bool) {
//    }
//
//    func dismiss() {
//        expHandleCancelButtonPressed.fulfill()
//    }
//}
//
//extension ClientCertificatePasswordViewModelTest: ClientCertificatePasswordViewModelPasswordChangeDelegate {
//    func didEnter(password: String) {
//        let exp = Constant.password
//        XCTAssertEqual(password, exp)
//        expHandleOkButtonPressed.fulfill()
//    }
//}
//
/// MARK: - Mock Data
//
//private struct Constant {
//    static let password = "1234"
//}
////XAVIER:
