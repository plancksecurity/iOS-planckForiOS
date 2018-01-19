//
//  AuthMethod.swift
//  pEp
//
//  Created by Dirk Zimmermann on 19.01.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import Foundation

public enum AuthMethod: String {
    case plain = "PLAIN"
    case login = "LOGIN"
    case cramMD5 = "CRAM-MD5"

    /** Pantomime requires XOAUTH2, but still working on error propagation */
    case saslXoauth2 = "SASL XOAUTH2"

    init?(string: String?) {
        guard let s = string else {
            return nil
        }
        if s.isEqual(AuthMethod.plain.rawValue) {
            self = .plain
        } else if s.isEqual(AuthMethod.login.rawValue) {
            self = .login
        } else if s.isEqual(AuthMethod.cramMD5.rawValue) {
            self = .cramMD5
        } else if s.isEqual(AuthMethod.saslXoauth2.rawValue) {
            self = .saslXoauth2
        } else {
            return nil
        }
    }
}
