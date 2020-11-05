//
//  NSError+Passphrase.swift
//  pEp
//
//  Created by Martin Brude on 05/10/2020.
//  Copyright © 2020 p≡p Security S.A. All rights reserved.
//

import Foundation
import PEPObjCAdapterFramework

public extension NSError {

    /// Indicates if the error is PASSPHRASE related.
    /// That means: if it is a passphraseRequired error or a wrong passphrase error.
    var isPassphraseError: Bool {
        if domain == PEPObjCAdapterEngineStatusErrorDomain {
            let pEpStatus = PEPStatus(rawValue: Int32(code))
            if pEpStatus == .passphraseRequired || pEpStatus == .wrongPassphrase {
                return true
            } else {
                return false
            }
        }
        return false
    }
}
