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
        let result = checkBasicVerification() { v in
            var verifiable = v

            // This should make it fail quickly
            verifiable.serverIMAP = "localhost"
            verifiable.portIMAP = 5
            verifiable.serverSMTP = "localhost"
            verifiable.portSMTP = 5

            return verifiable
        }
        switch result {
        case .success(_):
            XCTFail()
        case .failure(_):
            break
        }
    }

    func testBasicFailingVerificationWithWrongPassword() {
        let result = checkBasicVerification() { v in
            var verifiable = v

            verifiable.password = "xxxxxxxxxx"

            return verifiable
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

    enum TestError: Error {
        case noResult
    }

    /// Expects a failure, lets caller modify the `VerifiableAccountProtocol`.
    func checkBasicVerification(
        modifier: (VerifiableAccountProtocol) -> VerifiableAccountProtocol)
        -> Result<Void, Error> {
            let verifier = VerifiableAccount()
            var verifiable: VerifiableAccountProtocol = verifier
            SecretTestData().populateWorkingAccount(
                verifiableAccount: &verifiable)

            verifiable = modifier(verifiable)

            let expDidVerify = expectation(description: "expDidVerify")
            let delegate = VerifiableAccountTestDelegate(expDidVerify: expDidVerify)
            try! check(verifier: &verifiable, delegate: delegate)
            wait(for: [expDidVerify], timeout: TestUtil.waitTime)

            guard let result = delegate.result else {
                XCTFail()
                return .failure(TestError.noResult)
            }

            return result
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
