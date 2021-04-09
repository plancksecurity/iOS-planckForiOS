//
//  AccountType.swift
//  pEp
//
//  Created by Dirk Zimmermann on 09.04.21.
//  Copyright © 2021 p≡p Security S.A. All rights reserved.
//

import Foundation

public enum AccountType: CaseIterable {
    case gmail
    case other
    case clientCertificate
    case o365
    case icloud
    case outlook

    public var isOauth: Bool {
        return self == .gmail
    }
}
