//
//  NSError+Passphrase.swift
//  pEp
//
//  Created by Martin Brude on 05/10/2020.
//  Copyright © 2020 p≡p Security S.A. All rights reserved.
//

import Foundation
import PEPObjCAdapterTypes_iOS
import PEPObjCAdapter_iOS

public extension NSError {

    /// Indicates if the error is PASSPHRASE related.
    /// That means: if it is a passphraseRequired error or a wrong passphrase error.
    var isPassphraseError: Bool {
        if domain == PEPObjCAdapterEngineStatusErrorDomain &&
            code == Int(PEPStatus.passphraseRequired.rawValue) ||
            code == Int(PEPStatus.wrongPassphrase.rawValue) {
            return true
        } else {
            return false
        }
    }
}
