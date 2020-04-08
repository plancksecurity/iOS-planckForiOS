//
//  ClientCertificateManagmentViewModelTest.swift
//  pEpForiOSTests
//
//  Created by Xavier Algarra on 02/04/2020.
//  Copyright © 2020 p≡p Security S.A. All rights reserved.
//

import XCTest
@testable import pEpForiOS
@testable import MessageModel
import PantomimeFramework
import PEPObjCAdapterFramework

final class ClientCertificateManagmentViewModelTest: XCTestCase {
    
    private var vm: ClientCertificateManagementViewModel?

    override func setUp() {
        super.setUp()
    }

    override func tearDown() {
        vm = nil
    }

    func testNumberOfRows() {
        let numerOfExpectedCerts = 1
        let account = VerifiablAccountUtilMockTest()
        let clientCertUtil = ClientCertificateManagementUtilMockTest()
        vm = ClientCertificateManagementViewModel(verifiableAccount: account, clientCertificateUtil: clientCertUtil, account: nil)
        XCTAssertEqual(numerOfExpectedCerts, vm?.rows.count)
    }
    
    func testCertificateRemoved() {
        let numberOfExpectedcerts = 1
        let account = VerifiablAccountUtilMockTest()
        let clientCertUtil = ClientCertificateManagementUtilMockTest()
        vm = ClientCertificateManagementViewModel(verifiableAccount: account, clientCertificateUtil: clientCertUtil, account: nil)
        XCTAssertEqual(numberOfExpectedcerts, vm?.rows.count)
        XCTAssertTrue(((vm?.deleteCertificate(indexPath: IndexPath(row: 0, section: 0))) != false))
        let cuantityOfDeletedCerts = 1
        XCTAssertEqual(numberOfExpectedcerts - cuantityOfDeletedCerts, vm?.rows.count)
    }
}

class VerifiablAccountUtilMockTest: VerifiableAccountProtocol {
    
    var verifiableAccountDelegate: VerifiableAccountDelegate?
    var accountType: VerifiableAccount.AccountType = .other
    var keySyncEnable: Bool = false
    var loginNameIMAP: String?
    var loginNameSMTP: String?
    var address: String?
    var userName: String?
    var loginName: String?
    var authMethod: AuthMethod?
    var password: String?
    var accessToken: OAuth2AccessTokenProtocol?
    var clientCertificate: ClientCertificate?
    var serverIMAP: String?
    var portIMAP: UInt16 = 993
    var transportIMAP: ConnectionTransport = .TLS
    var serverSMTP: String?
    var portSMTP: UInt16 = 587
    var transportSMTP: ConnectionTransport = .startTLS
    var isAutomaticallyTrustedImapServer = false
    var isManuallyTrustedImapServer = false
    
    func verify() throws {
        return
    }
    
    func save(completion: ((Success) -> ())?) throws {
        return
    }
    
    var loginNameIsValid: Bool = true
    var isValidUser: Bool = true
    var containsCompleteServerInfo: Bool = true
}

class ClientCertificateManagementUtilMockTest: ClientCertificateUtilProtocol {
    var listOfCerts = [ClientCertificate]()
    func listCertificates(session: Session?) -> [ClientCertificate] {
        listOfCerts.append(ClientCertificate(cdObject: CdClientCertificate(),
                                                 context: Session.main.moc))
        return listOfCerts
    }
    
    func storeCertificate(p12Data: Data, password: String) throws {
        return
    }
    
    func delete(clientCertificate: ClientCertificate) throws {
        listOfCerts.removeAll()
    }
}
