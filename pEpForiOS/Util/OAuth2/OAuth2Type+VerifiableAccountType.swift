//
//  OAuth2Type+VerifiableAccountType.swift
//  pEp
//
//  Created by Dirk Zimmermann on 29.04.20.
//  Copyright © 2020 p≡p Security S.A. All rights reserved.
//

import Foundation

#if EXT_SHARE
import MessageModelForAppExtensions
#else
import MessageModel
#endif

extension OAuth2Type {
    init?(accountType: VerifiableAccount.AccountType) {
        switch accountType {
        case .gmail:
            self = .google
        case .other, .clientCertificate, .o365, .icloud, .outlook:
            return nil
        }
    }
}
