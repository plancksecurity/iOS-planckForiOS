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
    init?(accountType: AccountType) {
        switch accountType {
        case .gmail:
            self = .google
        case .other, .clientCertificate, .o365, .icloud, .outlook:
            return nil
        }
    }
}
