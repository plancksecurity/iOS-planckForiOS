//
//  OAuth2Type+VerifiableAccountType.swift
//  pEp
//
//  Created by Dirk Zimmermann on 29.04.20.
//  Copyright © 2020 p≡p Security S.A. All rights reserved.
//

import Foundation

import MessageModel

extension OAuth2Type {
    init?(accountType: VerifiableAccount.AccountType) {
        switch accountType {
        case .gmail:
            self = .google
        case .o365:
            self = .o365
        case .other, .clientCertificate, .icloud, .outlook:
            return nil
        }
    }

    func accountType() -> VerifiableAccount.AccountType {
        switch self {
        case .google: return VerifiableAccount.AccountType.gmail
        case .o365: return VerifiableAccount.AccountType.o365
        }
    }
}
