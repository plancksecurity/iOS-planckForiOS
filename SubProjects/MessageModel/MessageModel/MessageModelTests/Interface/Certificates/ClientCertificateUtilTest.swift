//
//  ClientCertificateUtilTest.swift
//  MessageModelTests
//
//  Created by Dirk Zimmermann on 19.02.20.
//  Copyright © 2020 pEp Security S.A. All rights reserved.
//

import XCTest
import Foundation

@testable import MessageModel

class ClientCertificateUtilTest: PersistentStoreDrivenTestBase {
    var certUtil: ClientCertificateUtil!

    override func setUp() {
        super.setUp()
        certUtil = ClientCertificateUtil()
    }

    func testLoadSingleCertificate() {
        storeCertificate(filename: "Certificate_001.p12", password: "uiae")
        XCTAssertEqual(certUtil.listCertificates().count, 1)
    }

    func testLoadMultipleCertificate() {
        storeCertificate(filename: "Certificate_001.p12", password: "uiae")
        storeCertificate(filename: "Certificate_002.p12", password: "uiae")
        storeCertificate(filename: "Certificate_003.p12", password: "uiae")
        XCTAssertEqual(certUtil.listCertificates().count, 3)
    }

    func testDeleteMultipleCertificates() {
        storeCertificate(filename: "Certificate_001.p12", password: "uiae")
        storeCertificate(filename: "Certificate_002.p12", password: "uiae")
        storeCertificate(filename: "Certificate_003.p12", password: "uiae")
        let certs = certUtil.listCertificates()
        for cert in certs {
            do {
                try ClientCertificateUtil().delete(clientCertificate: cert)
            } catch {
                XCTFail()
            }
        }
        XCTAssertEqual(certUtil.listCertificates().count, 0)
    }

    func testDeleteCertificateThatIsStillUsed() {
        storeCertificate(filename: "Certificate_001.p12", password: "uiae")

        let moc = Stack.shared.newPrivateConcurrentContext

        var counter = 0
        let certs = certUtil.listCertificates()
        var shouldBreak = false
        for cert in certs {
            moc.performAndWait {
                guard let cdCert = (CdClientCertificate.all(in: moc) as? [CdClientCertificate])?.first else {
                    XCTFail()
                    shouldBreak = true
                    return
                }
                let cdIdentity = CdIdentity(context: moc)
                cdIdentity.userName = "userName_\(counter)"
                cdIdentity.address = "address_\(counter)"

                let cdAccount = CdAccount(context: moc)
                cdAccount.identity = cdIdentity

                let cdServer = CdServer(context: moc)
                cdServer.address = "server_address_\(counter)"
                cdServer.port = 777
                cdServer.serverType = .imap
                cdServer.transport = .tls

                let cdCreds = CdServerCredentials(context: moc)
                cdCreds.clientCertificate = cdCert
                cdCreds.key = "key_\(counter)"
                cdCreds.loginName = "loginName_\(counter)"

                cdServer.credentials = cdCreds

                cdAccount.addToServers(cdServer)

                moc.saveAndLogErrors()
            }
            if shouldBreak {
                break
            }
            do {
                try ClientCertificateUtil().delete(clientCertificate: cert)
                XCTFail()
            } catch {
            }
            counter = counter + 1
        }
        XCTAssertEqual(certUtil.listCertificates().count, 1)
    }

    func testDoubleDeleteCertificate() {
        storeCertificate(filename: "Certificate_001.p12", password: "uiae")
        let certs = certUtil.listCertificates()
        for cert in certs {
            do {
                try ClientCertificateUtil().delete(clientCertificate: cert)
                try ClientCertificateUtil().delete(clientCertificate: cert)
            } catch {
                XCTFail()
            }
        }
        XCTAssertEqual(certUtil.listCertificates().count, 0)
    }

    func testIsCertificate() {
        XCTAssertTrue(ClientCertificatesTestUtil.isCertificate(filename: "Certificate_001.p12"))
        XCTAssertTrue(ClientCertificatesTestUtil.isCertificate(filename: "Certificate_002.p12"))
        XCTAssertTrue(ClientCertificatesTestUtil.isCertificate(filename: "Certificate_003.p12"))
        XCTAssertFalse(ClientCertificatesTestUtil.isCertificate(filename: "Not_a_certificate.p12"))
    }

    // MARK: - Helpers

    private func storeCertificate(filename: String, password: String) {
        XCTAssertTrue(ClientCertificatesTestUtil.storeCertificate(filename: filename,
                                                                  password: password))
    }
}
