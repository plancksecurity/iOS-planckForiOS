//
//  ClientCertificates+TestUtils.swift
//  MessageModelTests
//
//  Created by Dirk Zimmermann on 20.02.20.
//  Copyright © 2020 pEp Security S.A. All rights reserved.
//

import Foundation

import MessageModel

class ClientCertificatesTestUtil {
    /// Load a certificate from the given bundle resource, unlock it with the
    /// given password and store it in core data for later retrieval.
    /// - Parameters:
    ///   - filename: The bundle resource representing the certificate data
    ///   - password: The password to unlock the certificate
    static func storeCertificate(filename: String, password: String) -> Bool {
        let testBundle = Bundle(for: ClientCertificatesTestUtil.self)
        guard let url = testBundle.url(forResource: filename,
                                       withExtension: nil) else {
                                        return false
        }

        guard let p12Data = try? Data(contentsOf: url) else {
            return false
        }

        do {
            try ClientCertificateUtil().storeCertificate(p12Data: p12Data, password: password)
        } catch {
            return false
        }

        return true
    }
}
