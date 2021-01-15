//
//  Error+Passphrase.swift
//  pEp
//
//  Created by Martin Brude on 05/10/2020.
//  Copyright © 2020 p≡p Security S.A. All rights reserved.
//

import Foundation

public extension Error {

    /// Indicates if the error is PASSPHRASE related.
    /// That means: if it is a passphraseRequired error or a wrong passphrase error.
    var isPassphraseError: Bool {
        let nserror = self as NSError
        return nserror.isPassphraseError
    }
}

