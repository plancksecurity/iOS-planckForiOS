//
//  VerifiableAccountProtocol+UI.swift
//  pEp
//
//  Created by Dirk Zimmermann on 18.04.19.
//  Copyright © 2019 p≡p Security S.A. All rights reserved.
//

import Foundation

import MessageModel

/// Used by the UI.
public extension VerifiableAccountProtocol {
    public var isValidName: Bool {
        return (userName?.count ?? 0) >= 1
    }

    public var isValidUser: Bool {
        return isValidName && isValidEmail && isValidPassword
    }

    private var isValidEmail: Bool {
        return address?.isProbablyValidEmail() ?? false
    }

    private var isValidPassword: Bool {
        if let pass = password {
            return pass.count > 0
        }
        return false
    }
}
