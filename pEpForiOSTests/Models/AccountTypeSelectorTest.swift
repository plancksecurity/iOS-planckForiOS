//
//  AccountTypeSelectorTest.swift
//  pEpForiOSTests
//
//  Created by Xavier Algarra on 06/03/2020.
//  Copyright © 2020 p≡p Security S.A. All rights reserved.
//

import XCTest
@testable import pEpForiOS
@testable import MessageModel
import PantomimeFramework

class AccountTypeSelectorTest: AccountDrivenTestBase {
    
    func testNoPreviousAccount() {
        let vm = AccountTypeSelectorViewModel()
        Account.all().forEach { (acc) in
            acc.delete()
        }
        XCTAssertFalse(vm.isThereAnAccount())
    }
    
    func testThereIsAPreviousAccount() {
        let account = TestData().createWorkingAccount()
        account.session.commit()
        let vm = AccountTypeSelectorViewModel()
        XCTAssertTrue(vm.isThereAnAccount())
    }

    func testNoClientCertificateAlert() {
        let delegateExpectation = expectation(description: "delegateExpectation")
        let vmDelegate = AccountTypeDelegateMockTest(noClientCertificatesExpectation: delegateExpectation)
        let clientCertificateUtil = ClientCertificateUtilMockTest()
        let vm = AccountTypeSelectorViewModel(clientCertificateUtil: clientCertificateUtil)
        vm.delegate = vmDelegate
        vm.handleDidChooseClientCertificate()
        waitForExpectations(timeout: TestUtil.waitTime)

    }
    
    func testClientCertificateAlert() {
        let delegateExpectation = expectation(description: "delegateExpectation")
        let vmDelegate = AccountTypeDelegateMockTest(thereAreClientCertificatesExpectation: delegateExpectation)
        let clientCertificateUtil = ClientCertificateUtilMockTest(thereAreCerts: true)
        let vm = AccountTypeSelectorViewModel(clientCertificateUtil: clientCertificateUtil)
        vm.delegate = vmDelegate
        vm.handleDidChooseClientCertificate()
        waitForExpectations(timeout: TestUtil.waitTime)
    }
    
    func testAccountTypeSelectorNames() {
        let account = TestData().createWorkingAccount()
        account.session.commit()
        let vm = AccountTypeSelectorViewModel()
        XCTAssertEqual(vm.fileNameOrText(provider: .clientCertificate), """
 Client
 Certificate
 """)
        /// Localized value to pass the test even if the simulator is configured in other language.
        let otherText = NSLocalizedString("Other", comment: "Other")
        XCTAssertEqual(vm.fileNameOrText(provider: .gmail), "asset-Google")
        XCTAssertEqual(vm.fileNameOrText(provider: .other), otherText)
    }
}

class AccountTypeDelegateMockTest: AccountTypeSelectorViewModelDelegate {
    
    let noClientCertificatesExpectation: XCTestExpectation?
    let thereAreClientCertificatesExpectation: XCTestExpectation?
    
    init(noClientCertificatesExpectation: XCTestExpectation? = nil,
         thereAreClientCertificatesExpectation: XCTestExpectation? = nil) {
        self.noClientCertificatesExpectation = noClientCertificatesExpectation
        self.thereAreClientCertificatesExpectation = thereAreClientCertificatesExpectation
    }
    
    func showMustImportClientCertificateAlert() {
        if let noClientCertificatesExpectation = noClientCertificatesExpectation {
            noClientCertificatesExpectation.fulfill()
        } else {
            XCTFail()
        }
    }
    
    func showClientCertificateSeletionView() {
        if let thereAreClientCertificatesExpectation = thereAreClientCertificatesExpectation {
            thereAreClientCertificatesExpectation.fulfill()
        } else {
            XCTFail()
        }
    }
}

class ClientCertificateUtilMockTest: ClientCertificateUtilProtocol {
    let cert: Bool
    init(thereAreCerts: Bool = false) {
        cert = thereAreCerts
    }
    func listCertificates(session: Session?) -> [ClientCertificate] {
        var listOfCerts = [ClientCertificate]()
        if cert {
            listOfCerts.append(ClientCertificate(cdObject: CdClientCertificate(),
                                                 context: Session.main.moc))
        }
        return listOfCerts
    }
    
    func storeCertificate(p12Data: Data, password: String) throws {}

    func delete(clientCertificate: ClientCertificate) throws {}

    func isCertificate(p12Data: Data) -> Bool {
        return false
    }
}
