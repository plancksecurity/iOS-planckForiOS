//
//  ClientCertificateUtilTestInternal.swift
//  MessageModelTests
//
//  Created by Dirk Zimmermann on 20.02.20.
//  Copyright © 2020 pEp Security S.A. All rights reserved.
//

import XCTest

@testable import MessageModel

class ClientCertificateUtilTestInternal: PersistentStoreDrivenTestBase {
    var certUtil: ClientCertificateUtil!

    override func setUp() {
        super.setUp()
        certUtil = ClientCertificateUtil()
    }

    func testCompareLoadIdentity() {
        storeCertificate(filename: "Certificate_001.p12", password: "uiae")
        storeCertificate(filename: "Certificate_002.p12", password: "uiae")

        let certs = certUtil.listCertificates()

        let identitiesArray: [SecIdentity] = certs.compactMap {
            guard let uuid = $0.cdObject.keychainUuid else {
                XCTFail()
                return nil
            }
            return certUtil.loadIdentity(uuid: uuid)
        }

        XCTAssertTrue(identitiesArray.count == 2)
        let identitiesSet = Set(identitiesArray)
        XCTAssertEqual(identitiesSet.count, identitiesArray.count)
    }

    func testLoadIdentity() {
        storeCertificate(filename: "Certificate_001.p12", password: "uiae")
        let certs = certUtil.listCertificates()
        for cert in certs {
            guard
                let uuid = cert.cdObject.keychainUuid,
                let _ = certUtil.loadIdentity(uuid: uuid) else {
                XCTFail()
                return
            }
        }
    }

    // MARK: - Helpers

    private func storeCertificate(filename: String, password: String) {
        XCTAssertTrue(ClientCertificatesTestUtil.storeCertificate(filename: filename,
                                                                  password: password))
    }
}
