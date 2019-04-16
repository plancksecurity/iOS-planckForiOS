//
//  VerifiableAccountTest.swift
//  pEpForiOSTests
//
//  Created by Dirk Zimmermann on 16.04.19.
//  Copyright © 2019 p≡p Security S.A. All rights reserved.
//

import XCTest

import MessageModel
@testable import pEpForiOS

class VerifiableAccountTest: XCTestCase {
    func testBasicSuccess() {
        let verifier = VerifiableAccount()
        var verifierType: VerifiableAccountProtocol = verifier
        SecretTestData().populateWorkingAccount(
            verifiableAccount: &verifierType)
        let expDidVerify = expectation(description: "expDidVerify")
        let delegate = VerifiableAccountTestDelegate(expDidVerify: expDidVerify)
        try! check(verifier: &verifierType, delegate: delegate)
        wait(for: [expDidVerify], timeout: TestUtil.waitTime)
    }

    func testFailingValidation() {
        let (exceptionOnVerify, exceptionOnSave) = checkFailingValidation() {
            var newOne = $0
            newOne.address = nil
            return newOne
        }
        XCTAssertTrue(exceptionOnVerify)
        XCTAssertTrue(exceptionOnSave)
    }

    func testBasicFailingVerification() {
        let verifier = VerifiableAccount()
        var verifierType: VerifiableAccountProtocol = verifier
        SecretTestData().populateWorkingAccount(
            verifiableAccount: &verifierType)

        // This should make it fail quickly
        verifierType.serverIMAP = "localhost"
        verifierType.portIMAP = 5
        verifierType.serverSMTP = "localhost"
        verifierType.portSMTP = 5

        let expDidVerify = expectation(description: "expDidVerify")
        let delegate = VerifiableAccountTestDelegate(expDidVerify: expDidVerify)
        try! check(verifier: &verifierType, delegate: delegate)
        wait(for: [expDidVerify], timeout: TestUtil.waitTime)

        guard let result = delegate.result else {
            XCTFail()
            return
        }

        switch result {
        case .success(_):
            XCTFail()
        case .failure(_):
            break
        }
    }

    // MARK: Helpers

    /// Tries `verify()` and `save()` on the given `VerifiableAccountProtocol`.
    /// - Returns: A tuple of Bool denoting if `verify()` and `save()` threw exceptions.
    func checkFailingValidation(
        modifier: (VerifiableAccountProtocol) -> VerifiableAccountProtocol) -> (Bool, Bool) {
        let verifier = VerifiableAccount()
        var verifierType: VerifiableAccountProtocol = verifier
        SecretTestData().populateWorkingAccount(
            verifiableAccount: &verifierType)

        // Invalidate it
        var verifierToBeUsed = modifier(verifierType)

        var exceptionHit1 = false
        do {
            try check(verifier: &verifierToBeUsed, delegate: nil)
        } catch {
            exceptionHit1 = true
        }

        var exceptionHit2 = false
        do {
            try check(verifier: &verifierToBeUsed, delegate: nil)
        } catch {
            exceptionHit2 = true
        }

        return (exceptionHit1, exceptionHit2)
    }

    func check(verifier: inout VerifiableAccountProtocol,
               delegate: VerifiableAccountDelegate?) throws {
        verifier.verifiableAccountDelegate = delegate
        try verifier.verify()
    }
}

class VerifiableAccountTestDelegate: VerifiableAccountDelegate {
    var result: Result<Void, Error>?

    let expDidVerify: XCTestExpectation

    init(expDidVerify: XCTestExpectation) {
        self.expDidVerify = expDidVerify
    }

    func didEndVerification(result: Result<Void, Error>) {
        self.result = result
        expDidVerify.fulfill()
    }
}
