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
import PEPObjCAdapterFramework


class AccountTypeSelectorTest: CoreDataDrivenTestBase {
    
    func testNoPreviousAccount() {
        let vm = AccountTypeSelectorViewModel()
        Account.all().forEach { (acc) in
            acc.delete()
        }
        do {
            try moc.save()
        } catch {
            XCTFail()
        }
        XCTAssertFalse(vm.isThereAnAccount())
    }
    
    func testThereIsAPreviousAccount() {
        let account = SecretTestData().createWorkingAccount()
        account?.save()
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
        let account = SecretTestData().createWorkingAccount()
        account?.save()
        let vm = AccountTypeSelectorViewModel()
        XCTAssertEqual(vm.fileNameOrText(provider: .clientCertificate), """
 Client
 Certificate
 """)
        XCTAssertEqual(vm.fileNameOrText(provider: .gmail), "asset-Google")
        XCTAssertEqual(vm.fileNameOrText(provider: .other), "Other")
    }
    
    func testNumberOfSectionsWithoutCertificate() {
        let expectedSectionsWithoutCertificate = 5
        let vm = AccountTypeSelectorViewModel()
        XCTAssertEqual(expectedSectionsWithoutCertificate, vm.count)
    }
    
    func testNumberOfSectionsWithCertificate() {
        let expectedSectionsWithCertificate = 6
        let clientCertificateUtil = ClientCertificateUtilMockTest(thereAreCerts: true)
        let vm = AccountTypeSelectorViewModel(clientCertificateUtil: clientCertificateUtil)
        XCTAssertEqual(expectedSectionsWithCertificate, vm.count)
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
    
    func storeCertificate(p12Data: Data, password: String) throws {
        
    }

    func delete(clientCertificate: ClientCertificate) throws {}
}
