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
        case .other:
            return nil
        case .clientCertificate:
            return nil
        case .o365:
            return nil
        case .icloud:
            return nil
        case .outlook:
            return nil
        }
    }
}
