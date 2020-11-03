//
//  ClientCertificateUtil+Internal.swift
//  MessageModel
//
//  Created by Dirk Zimmermann on 19.02.20.
//  Copyright © 2020 pEp Security S.A. All rights reserved.
//

import Foundation

/// The MM-internal parts of the certificate service.
extension ClientCertificateUtil {
    /// Loads the certificate identified as a `SecIdentity`.
    /// - Parameter persistentDataID: The ID (in the form of `Data`) of the client certificate
    /// (identity) in the keychain.
    func loadIdentity(uuid: String) -> SecIdentity? {
        let existingTuples = listExisting()

        for (foundUuid, someSecIdentity) in existingTuples {
            if uuid == foundUuid {
                return someSecIdentity
            }
        }

        return nil
    }
}
