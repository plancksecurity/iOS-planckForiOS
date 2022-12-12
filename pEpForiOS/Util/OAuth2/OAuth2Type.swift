//
//  OAuth2Type.swift
//  pEp
//
//  Created by Dirk Zimmermann on 13.12.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import Foundation

/**
 The kind of endpoint/provider that should be used.
 Abstracts configuration.
 */
enum OAuth2Type {
    case google
    case yahoo
    case o365
}
