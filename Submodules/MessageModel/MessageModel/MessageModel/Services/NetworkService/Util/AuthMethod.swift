//
//  AuthMethod.swift
//  pEp
//
//  Created by Dirk Zimmermann on 19.01.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import Foundation

public enum AuthMethod: String {
    /**
     IMAP built-in LOGIN (https://tools.ietf.org/html/rfc3501#section-6.2.3)
     Every IMAP server supports this.
     */
    case simple = "NONE"

    case plain = "PLAIN"
    case login = "LOGIN"
    case cramMD5 = "CRAM-MD5"

    /** Pantomime requires XOAUTH2 */
    case saslXoauth2 = "XOAUTH2"

    init(string: String?) {
        if let s = string  {
            if s.isEqual(AuthMethod.plain.rawValue) {
                self = .plain
            } else if s.isEqual(AuthMethod.login.rawValue) {
                self = .login
            } else if s.isEqual(AuthMethod.cramMD5.rawValue) {
                self = .cramMD5
            } else if s.isEqual(AuthMethod.saslXoauth2.rawValue) {
                self = .saslXoauth2
            } else {
                self = .simple
            }
        } else {
            self = .simple
        }
    }
}
